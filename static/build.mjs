// Builds a static site with the craft app pages, for hosts that serve only files (Vercel, Netlify,
// Cloudflare Pages, GitHub Pages): node static/build.mjs [out dir, default public]
//
// The pages come out of the hayone/<app>:remote images on Docker Hub (the same pages the studio
// uses), so the build needs no Docker. Each app lands in <out>/<app>/. Settings:
//   CRAFT_APPS     the apps, comma separated (default: the five that craft-mcp drives)
//   IMAGE_TAG      the image tag (default remote)
//   NAMESPACE      the Docker Hub namespace (default hayone)
//   EMBED_ORIGINS  editors that may frame the apps and drive them, comma separated, e.g.
//                  https://*.code.example.com. Default vscode-webview://* (VS Code on the desktop).
//   EMBED_FILES    "false": those editors may not lend their workspace files to the apps.
// No dependencies: Node 18 or newer.
import { mkdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join, normalize } from "node:path";
import { gunzipSync } from "node:zlib";
import zlib from "node:zlib";

const env = process.env;
const OUT = process.argv[2] ?? "public";
const APPS = (env.CRAFT_APPS || "photocraft,vectorcraft,lightcraft,filmcraft,effectcraft").split(",").map((s) => s.trim()).filter(Boolean);
const TAG = env.IMAGE_TAG || "remote";
const NAMESPACE = env.NAMESPACE || "hayone";
const ROOT = "usr/share/nginx/html/";

const ORIGIN = /^[a-z][a-z0-9+.-]*:\/\/[a-z0-9*.-]+(:[0-9]+)?$/i;
const origins = (env.EMBED_ORIGINS ?? "vscode-webview://*").split(",").map((s) => s.trim().replace(/\/$/, "")).filter(Boolean);
for (const o of origins) if (!ORIGIN.test(o)) throw new Error(`EMBED_ORIGINS: bad origin ${o} (expected scheme://host[:port])`);
const files = String(env.EMBED_FILES ?? "true").toLowerCase() !== "false";

const MANIFESTS = [
  "application/vnd.oci.image.index.v1+json",
  "application/vnd.docker.distribution.manifest.list.v2+json",
  "application/vnd.oci.image.manifest.v1+json",
  "application/vnd.docker.distribution.manifest.v2+json",
].join(", ");

async function get(url, headers, tries = 4) {
  for (let i = 1; ; i++) {
    try {
      const r = await fetch(url, { headers });
      if (r.ok) return r;
      if (r.status < 500 && r.status !== 429) throw new Error(`${url}: HTTP ${r.status}`);
      if (i >= tries) throw new Error(`${url}: HTTP ${r.status}`);
    } catch (e) {
      if (i >= tries || /HTTP 4/.test(e.message)) throw e;
    }
    await new Promise((res) => setTimeout(res, 1000 * 2 ** i));
  }
}

/** The image's layers, oldest first, for linux/amd64 (the pages are the same on every platform). */
async function layers(repo) {
  const { token } = await (await get(`https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repo}:pull`)).json();
  const auth = { authorization: `Bearer ${token}` };
  const manifest = async (ref) => (await get(`https://registry-1.docker.io/v2/${repo}/manifests/${ref}`, { ...auth, accept: MANIFESTS })).json();
  let m = await manifest(TAG);
  if (m.manifests) {
    const pick = m.manifests.find((d) => d.platform?.os === "linux" && d.platform?.architecture === "amd64")
      ?? m.manifests.find((d) => d.platform?.os === "linux");
    if (!pick) throw new Error(`${repo}:${TAG} has no linux image`);
    m = await manifest(pick.digest);
  }
  return { auth, layers: m.layers };
}

/** Reads a tar archive; calls file(path, bytes) for regular files and gone(path) for whiteouts. */
function untar(buf, file, gone) {
  let pos = 0, longName = null, pax = {};
  const str = (o, n) => { const s = buf.subarray(o, o + n); const z = s.indexOf(0); return s.subarray(0, z < 0 ? n : z).toString("utf8"); };
  while (pos + 512 <= buf.length) {
    if (buf[pos] === 0) break; // end of archive
    const size = parseInt(str(pos + 124, 12).trim() || "0", 8);
    const type = String.fromCharCode(buf[pos + 156] || 48);
    const prefix = str(pos + 345, 155);
    let name = str(pos, 100);
    if (prefix && str(pos + 257, 6).startsWith("ustar")) name = `${prefix}/${name}`;
    const body = buf.subarray(pos + 512, pos + 512 + size);
    pos += 512 + Math.ceil(size / 512) * 512;
    if (type === "L") { longName = body.toString("utf8").replace(/\0+$/, ""); continue; }
    if (type === "x") {
      for (const line of body.toString("utf8").split("\n")) {
        const m = /^\d+ ([^=]+)=(.*)$/.exec(line);
        if (m) pax[m[1]] = m[2];
      }
      continue;
    }
    if (type === "g") continue;
    name = (pax.path ?? longName ?? name).replace(/^\.?\//, "");
    longName = null; pax = {};
    const base = name.split("/").pop();
    if (base.startsWith(".wh.")) { gone(join(dirname(name), base.slice(4)).replaceAll("\\", "/")); continue; }
    if (type === "0" || type === "\0" || type === "7") file(name, body);
  }
}

const unpack = (bytes, mediaType) => {
  if (/zstd/.test(mediaType)) {
    if (!zlib.zstdDecompressSync) throw new Error("a zstd layer needs Node 22.15 or newer");
    return zlib.zstdDecompressSync(bytes);
  }
  return /gzip/.test(mediaType) ? gunzipSync(bytes) : bytes;
};

async function site(app) {
  const repo = `${NAMESPACE}/${app}`;
  const { auth, layers: list } = await layers(repo);
  /** @type {Map<string, Buffer>} */
  const out = new Map();
  for (const layer of list) {
    const blob = Buffer.from(await (await get(`https://registry-1.docker.io/v2/${repo}/blobs/${layer.digest}`, auth)).arrayBuffer());
    untar(unpack(blob, layer.mediaType), (name, body) => {
      if (name.startsWith(ROOT) && !name.endsWith(".gz")) out.set(name.slice(ROOT.length), Buffer.from(body));
    }, (name) => {
      for (const k of [...out.keys()]) if (`${ROOT}${k}` === name || `${ROOT}${k}`.startsWith(`${name}/`)) out.delete(k);
    });
  }
  if (!out.has("index.html")) throw new Error(`${repo}:${TAG} has no ${ROOT}index.html`);
  const dir = join(OUT, app);
  for (const [name, body] of out) {
    const path = normalize(join(dir, name));
    if (!path.startsWith(normalize(dir))) throw new Error(`${repo}: ${name} leaves the folder`);
    mkdirSync(dirname(path), { recursive: true });
    writeFileSync(path, body);
  }
  mkdirSync(join(dir, "_embed"), { recursive: true });
  writeFileSync(join(dir, "_embed", "config.json"), `${JSON.stringify({ origins, files })}\n`);
  let bytes = 0;
  for (const b of out.values()) bytes += b.length;
  console.log(`${app}: ${out.size} files, ${(bytes / 1e6).toFixed(1)} MB`);
}

rmSync(OUT, { recursive: true, force: true });
mkdirSync(OUT, { recursive: true });
for (const app of APPS) await site(app);

const title = (a) => a.replace(/craft$/, "Craft").replace(/^./, (c) => c.toUpperCase());
writeFileSync(join(OUT, "index.html"), `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Craft apps</title>
<style>
  body { font: 16px/1.5 system-ui, sans-serif; max-width: 40rem; margin: 3rem auto; padding: 0 1rem; color: #222; }
  a.app { display: block; padding: .8rem 1rem; margin: .5rem 0; border: 1px solid #ccc; border-radius: .5rem; text-decoration: none; color: inherit; }
  a.app:hover { border-color: #666; }
  code { background: #f2f2f2; padding: 0 .25rem; border-radius: .25rem; }
  @media (prefers-color-scheme: dark) { body { background: #1e1e1e; color: #ddd; } a.app { border-color: #444; } code { background: #333; } }
</style>
</head>
<body>
<h1>Craft apps</h1>
<p>The <a href="https://github.com/storytold">storytold</a> craft apps, running in your browser. Your files stay on your device.</p>
${APPS.map((a) => `<a class="app" href="${a}/">${title(a)}</a>`).join("\n")}
<h2>Use them in VS Code</h2>
<p>Install <a href="https://github.com/hayone1/craft-vscode">Craft Apps</a> and set <code>craft.appUrl</code> to this site's address.
For a coding agent to drive the apps, the extension also needs a craft-mcp relay: see <a href="https://github.com/hayone1/craft-code">craft-vscode</a>.</p>
</body>
</html>
`);
console.log(`Site in ${OUT}/ (editors allowed to frame the apps: ${origins.join(", ") || "none"})`);
