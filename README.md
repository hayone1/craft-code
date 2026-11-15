# Craft Studio

Craft Studio is VS Code in the browser with Claude Code and the
[storytold](https://github.com/storytold) craft apps (PhotoCraft, VectorCraft, LightCraft,
FilmCraft and EffectCraft) already set up. You open one web address, sign in with a password, and
click an app. The app opens in an editor panel. Claude Code works in the panel next to the app and
can draw, edit and save in the app while you watch.

This repository holds the ways to deploy Craft Studio: deploy buttons, a Docker Compose file and a
Helm chart. Each one runs the same parts:

| Part | What the part does |
| --- | --- |
| [code-server](https://github.com/coder/code-server) | VS Code in the browser, behind a password. |
| [Claude Code](https://www.anthropic.com/claude-code) | The coding agent. Each person signs in with their own Claude account. |
| [Craft Apps](https://github.com/hayone1/craft-vscode) | The VS Code extension that opens the apps in panels and gives the coding agent one MCP server for all open apps. |
| [craft-mcp](https://hub.docker.com/r/hayone/craft-mcp) | The relay. The app pages in the browser and the coding agent in VS Code meet at the relay. |
| The app pages (`hayone/<app>:remote`) | The five craft apps as web pages. |

## Deploy with one click

| Host | Button | What you get |
| --- | --- | --- |
| Railway | [![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/craft-studio) | The whole studio in one container, with a volume and an HTTPS address. |
| Render | [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/hayone1/craft-studio) | The whole studio in one container, with a disk and an HTTPS address. |
| Hostinger | [![Deploy on Hostinger](https://assets.hostinger.com/vps/deploy.svg)](https://www.hostinger.com/docker-hosting?compose_url=https://raw.githubusercontent.com/hayone1/craft-studio/main/docker-compose.yml) | A VPS that runs [docker-compose.yml](docker-compose.yml): the whole studio with automatic HTTPS. |
| Vercel | [![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Fhayone1%2Fcraft-studio&project-name=craft-apps) | The five app pages only (see [Vercel and Netlify](#vercel-and-netlify)). |
| Netlify | [![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/hayone1/craft-studio) | The five app pages only (see [Vercel and Netlify](#vercel-and-netlify)). |

### After the deploy

1. Open the address that the host gives you, for example `https://craft-studio-production.up.railway.app`.
2. Sign in with the password. The section [The password](#the-password) says where each host
   shows the password.
3. Open the **Craft** view in VS Code's activity bar, and click an app, for example **VectorCraft**.
4. Open Claude Code (the Claude icon in the editor title bar) and sign in with your Claude account.
5. Ask Claude to work in the app, for example "Draw a gold star in VectorCraft and save it as
   star.svg in the project".

The first start takes one to two minutes, because the studio installs the newest Claude Code and
Craft Apps extensions from Open VSX. Later starts are faster.

### The password

The studio asks for a password, because anyone who signs in gets a full VS Code with a terminal.

- **Railway** makes a password when you deploy. Open the service, then **Variables**, and copy
  `PASSWORD`.
- **Render** makes a password when you deploy. Open the service, then **Environment**, and copy
  `PASSWORD`.
- **Hostinger** and other Docker hosts: set `PASSWORD` yourself, or leave the setting empty. With
  an empty setting, the studio makes a password on the first start and prints the password in the
  log: `docker compose logs studio | grep Password`.

To change the password, change the `PASSWORD` setting and restart the studio.

## Docker Compose (any server)

[docker-compose.yml](docker-compose.yml) runs the studio on one server with automatic HTTPS from
Let's Encrypt. The Hostinger button uses the same file. The server needs Docker, ports 80 and 443
open, and at least 2 GB of memory.

1. Copy the file to the server, or clone this repository.
2. Copy `.env.example` to `.env`, and fill in the settings that you want. Every setting is optional.
3. Run `docker compose up -d`.
4. Run `docker compose logs setup` to see the address, for example `https://203-0-113-7.sslip.io`.
5. Open the address and sign in.

| Setting in `.env` | What the setting does |
| --- | --- |
| `DOMAIN` | The address, for example `studio.example.com`. Create a DNS record that points the name at the server first, because Let's Encrypt checks the name before it gives a certificate. Without `DOMAIN`, the setup uses the server's public IP address as `<ip>.sslip.io`. The [sslip.io](https://sslip.io) service turns such a name back into the IP address, so no DNS set-up is needed. |
| `PASSWORD` | The sign-in password. Without it, the studio makes one and prints it in the log. |
| `ACME_EMAIL` | An email address. Let's Encrypt writes to this address before a certificate runs out. |

The Compose file runs each part in its own container: Caddy (HTTPS), the studio, the relay and
the five apps. A small `setup` container runs first at every start. The `setup` container works
out the address and makes the relay's secrets on the first start. The secrets stay in the `setup`
volume, and your projects stay in the `home` volume.

To update every part to the newest images, run `docker compose pull && docker compose up -d`.

## Helm chart (Kubernetes)

The chart in [charts/craft-studio](charts/craft-studio) runs the studio, the relay and each app in
their own pods. The chart needs the address that people open, and an Ingress or a Gateway API
route that sends the address to the studio.

```sh
helm install studio oci://ghcr.io/hayone1/charts/craft-studio \
  --set host=studio.example.com \
  --set ingress.enabled=true --set ingress.className=nginx \
  --set 'ingress.tls[0].secretName=studio-tls' --set 'ingress.tls[0].hosts[0]=studio.example.com'
```

The chart makes a password once and keeps the password across upgrades. Read the password with
`kubectl get secret studio-craft-studio -o jsonpath='{.data.password}' | base64 -d`.

| Value | What the value does |
| --- | --- |
| `host` | The address without `https://`, for example `studio.example.com`. |
| `publicUrl` | The full address, when the address is not `https://<host>`. Use `http://localhost:8080` for a test with `kubectl port-forward`. |
| `auth.mode` | `password` (default) or `none`. Use `none` only when another sign-in, such as oauth2-proxy, protects the address. |
| `auth.password` | A password of your own. Empty: the chart makes one. |
| `ingress.*` | An Ingress for `host`. The default annotations keep ingress-nginx from closing the WebSockets after 60 seconds. |
| `httpRoute.*` | A Gateway API HTTPRoute for `host`, instead of an Ingress. |
| `studio.persistence.*` | The volume for `/home/coder` (10 GB by default). |
| `apps.enabled`, `relay.enabled` | Set both to `false` to run everything in the studio pod. |

[values.yaml](charts/craft-studio/values.yaml) lists every value with an explanation.

## Vercel and Netlify

Vercel and Netlify serve files and short functions. They can't run a container that stays on,
and they can't hold the WebSocket connections that the relay needs. So these two buttons deploy
only the five app pages, without VS Code and without the relay.

The static site is useful in two cases:

- People can use the apps in a browser tab. The files that the apps open stay on the person's
  device.
- VS Code on your own computer can show the apps. Install
  [Craft Apps](https://github.com/hayone1/craft-vscode) and set `craft.appUrl` to the site's
  address, for example `https://craft-apps.vercel.app`. For Claude Code to drive the apps, the
  extension also needs a relay. Use the relay of a Craft Studio that you deployed with another
  button: set `craft.relayUrl` to `https://<studio address>/relay` and set the relay token with
  **Craft: Set the Relay Token**. The relay token is `STUDIO_MINT_TOKEN` in the studio's
  `/home/coder/.craft-studio/secrets.env`.

The build (`node static/build.mjs`) downloads the app pages from the `hayone/<app>:remote` images
on Docker Hub, so the build needs no Docker. Set `EMBED_ORIGINS` in the host's environment
settings to choose which editors may frame the apps. The default is `vscode-webview://*`, which
is VS Code on the desktop.

## Limits

- **One person per studio.** A studio has one password and one home folder. For a team, deploy
  one studio per person, or use [Coder](https://coder.com) with the
  [content-studio template](https://github.com/hayone1/coder-templates), which gives each person
  their own workspace.
- **HTTPS is needed.** Browsers run VS Code's panels only on `https://` addresses or on
  `localhost`. Every deploy option here gives HTTPS, except a plain `docker run` on a server.
- **The app pages share the editor's address.** code-server shows each app through its port
  proxy (`/proxy/<port>/`), so the apps and VS Code have the same origin. The studio serves only
  the five app pages from its own images there.
- **VectorCraft is large.** The VectorCraft page has a 98 MB WebAssembly file. Vercel refuses
  files of 100 MB or more, so a bigger VectorCraft release would break the Vercel build until the
  build splits the file.
- **Railway, Render and Hostinger cost money.** Each host needs a paid plan for a volume or a
  VPS. The studio needs about 1 GB of memory when idle and 2 to 4 GB while Claude Code works.

## Run the studio with plain Docker

```sh
docker run -d -p 8080:8080 -v craft-home:/home/coder -e PASSWORD=choose-a-password hayone/craft-studio
```

Open `http://localhost:8080`. The image's own settings are in the
[image README](https://github.com/hayone1/Docker_Images/tree/main/craft-studio).

## How the repository is tested

The GitHub Action in [.github/workflows/ci.yml](.github/workflows/ci.yml) checks every deploy
option on each change:

- The static site is built, and the job checks that each app has its page and its editor
  settings.
- The Helm chart is linted, rendered in three shapes, and installed into a [kind](https://kind.sigs.k8s.io)
  cluster. The job then signs in and checks the relay and an app.
- The Compose file runs on the runner with `DOMAIN=localhost`. The job checks HTTPS, the sign-in,
  the relay, a relay connection and the five apps.

The image itself is built and tested in
[hayone1/Docker_Images](https://github.com/hayone1/Docker_Images/tree/main/craft-studio).

## License

MIT
