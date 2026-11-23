# Craft Code

Craft Code is VS Code in the browser with Claude Code and the
[storytold](https://github.com/storytold) craft apps (PhotoCraft, VectorCraft, LightCraft,
FilmCraft, EffectCraft, WordCraft, GridCraft and DeckCraft) already set up. You open a web address, sign in, and click an app. The
app opens in an editor panel. Claude Code works in the panel next to the app and can draw, edit
and save in the app while you watch.

This repository deploys Craft Code in two ways. Pick the option that fits the number of people:

| Option | For | Sign-in | Deploy with |
| --- | --- | --- | --- |
| [craft-vscode](#craft-vscode-one-person) | One person | One shared password | Railway, Render, Hostinger, Docker Compose, Helm |
| [craft-coder](#craft-coder-a-team) | A team | A Coder account per person, with an optional GitHub or OIDC sign-in | Hostinger, Docker Compose, Helm |

Both options run the same parts:

| Part | What the part does |
| --- | --- |
| [code-server](https://github.com/coder/code-server) | VS Code in the browser. |
| [Claude Code](https://www.anthropic.com/claude-code) | The coding agent. Each person signs in with their own Claude account. |
| [Craft Apps](https://github.com/hayone1/craft-vscode) | The VS Code extension that opens the apps in panels and gives the coding agent one MCP server for all open apps. |
| [craft-mcp](https://hub.docker.com/r/hayone/craft-mcp) | The relay. The app pages in the browser and the coding agent in VS Code meet at the relay. |
| The app pages (`hayone/<app>:remote`) | The craft apps as web pages: PhotoCraft, VectorCraft, LightCraft, FilmCraft, EffectCraft, WordCraft, GridCraft and DeckCraft. |

The image [`hayone/craft-code`](https://hub.docker.com/r/hayone/craft-code) has two tags. The tag
`vscode` (also `latest`) is the whole craft-vscode studio in one container. The tag `workspace`
is the workspace that craft-coder starts for each person.

## craft-vscode: one person

craft-vscode runs VS Code, the relay and the apps in one container, behind one password. Hosts
that run a single container can run craft-vscode, so craft-vscode has the most deploy buttons.

| Host | Button | What you get |
| --- | --- | --- |
| Railway | [![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/craft-vs-code) | The whole studio in one container, with a volume and an HTTPS address. |
| Render | [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/hayone1/craft-code) | The whole studio in one container, with a disk and an HTTPS address. |
| Hostinger | [![Deploy on Hostinger](https://assets.hostinger.com/vps/deploy.svg)](https://www.hostinger.com/docker-hosting?compose_url=https://raw.githubusercontent.com/hayone1/craft-code/main/vscode/docker-compose.yml) | A VPS that runs [vscode/docker-compose.yml](vscode/docker-compose.yml), with automatic HTTPS. |
| Vercel | [![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Fhayone1%2Fcraft-code&project-name=craft-apps&env=CRAFT_APPS&envDescription=The%20craft%20apps%20to%20deploy%2C%20comma%20separated&envDefaults=%7B%22CRAFT_APPS%22%3A%22photocraft%2Cvectorcraft%2Clightcraft%2Cfilmcraft%2Ceffectcraft%2Cwordcraft%2Cgridcraft%2Cdeckcraft%22%7D) | The app pages only (see [Vercel and Netlify](#vercel-and-netlify)). |
| Netlify | [![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/hayone1/craft-code) | The app pages only (see [Vercel and Netlify](#vercel-and-netlify)). |

### After the deploy

1. Open the address that the host gives you, for example `https://craft-vscode-production.up.railway.app`.
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
The password page is code-server's own sign-in page.

- **Railway** makes a password when you deploy. Open the service, then **Variables**, and copy
  `PASSWORD`.
- **Render** makes a password when you deploy. Open the service, then **Environment**, and copy
  `PASSWORD`.
- **Hostinger** and other Docker hosts: set `PASSWORD` yourself, or leave the setting empty. With
  an empty setting, the studio makes a password on the first start and prints the password in the
  log: `docker compose logs studio | grep Password`.

To change the password, change the `PASSWORD` setting and restart the studio.

### Docker Compose (any server)

[vscode/docker-compose.yml](vscode/docker-compose.yml) runs the studio on one server with
automatic HTTPS from Let's Encrypt. The Hostinger button uses the same file. The server needs
Docker, ports 80 and 443 open, and at least 2 GB of memory.

1. Clone this repository on the server, and open the `vscode` folder.
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
the apps. A small `setup` container runs first at every start. The `setup` container works
out the address and makes the relay's secrets on the first start. The secrets stay in the `setup`
volume, and your projects stay in the `home` volume.

To update every part to the newest images, run `docker compose pull && docker compose up -d`.

### Helm chart (Kubernetes)

The chart in [charts/craft-vscode](charts/craft-vscode) runs the studio, the relay and each app in
their own pods. The chart needs the address that people open, and an Ingress or a Gateway API
route that sends the address to the studio.

```sh
helm install studio oci://ghcr.io/hayone1/charts/craft-vscode \
  --set host=studio.example.com \
  --set ingress.enabled=true --set ingress.className=nginx \
  --set 'ingress.tls[0].secretName=studio-tls' --set 'ingress.tls[0].hosts[0]=studio.example.com'
```

The chart makes a password once and keeps the password across upgrades. Read the password with
`kubectl get secret studio-craft-vscode -o jsonpath='{.data.password}' | base64 -d`.

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

[values.yaml](charts/craft-vscode/values.yaml) lists every value with an explanation.

### Plain Docker

```sh
docker run -d -p 8080:8080 -v craft-home:/home/coder -e PASSWORD=choose-a-password hayone/craft-code
```

Open `http://localhost:8080`. The image's own settings are in the
[image README](https://github.com/hayone1/Docker_Images/tree/main/craft-code).

## craft-coder: a team

craft-coder runs a [Coder](https://coder.com) server. Coder gives each person an account and their
own workspace. A workspace is a container with VS Code, Claude Code and the Craft Apps extension,
and the person's own home folder. The relay and the apps run once, next to Coder, and every
workspace uses them.

The first start makes the server ready to use, so nobody has to set up Coder by hand:

1. A bootstrap step creates the admin account.
2. The bootstrap step adds the template `craft`, which describes a workspace.
3. The bootstrap step creates and starts a workspace called `studio` for the admin.

Coder starts every workspace as a new container (Docker) or a new pod (Kubernetes). Railway,
Render, Vercel and Netlify can't start containers from inside an app, so craft-coder can't run
there. Use a server with Docker, or a Kubernetes cluster.

| Host | Button | What you get |
| --- | --- | --- |
| Hostinger | [![Deploy on Hostinger](https://assets.hostinger.com/vps/deploy.svg)](https://www.hostinger.com/docker-hosting?compose_url=https://raw.githubusercontent.com/hayone1/craft-code/main/coder/docker-compose.yml) | A VPS that runs [coder/docker-compose.yml](coder/docker-compose.yml), with automatic HTTPS. |

### After the deploy

1. Open the address. The `setup` log shows the address: `docker compose logs setup`.
2. Sign in as `admin@example.com` (or your `ADMIN_EMAIL`) with the admin password. The `setup`
   log shows the password too. On Kubernetes, the chart's notes show the command that reads the
   password.
3. Open the workspace `studio`, and click **code-server**. VS Code opens.
4. Use the apps and Claude Code as described in craft-vscode's [After the deploy](#after-the-deploy).
5. Add people under **Admin settings** > **Users**, or turn on GitHub or OIDC sign-in (see
   [Sign-in](#sign-in)). Each person then creates their own workspace from the `craft` template.

### Docker Compose (any server)

[coder/docker-compose.yml](coder/docker-compose.yml) runs craft-coder on one server with automatic
HTTPS. The Hostinger button uses the same file. The server needs Docker, ports 80 and 443 open,
and about 2 GB of memory for Coder plus 2 to 4 GB for each running workspace.

1. Clone this repository on the server, and open the `coder` folder.
2. Copy `.env.example` to `.env`, and fill in the settings that you want. Every setting is optional.
3. Run `docker compose up -d`.
4. Run `docker compose logs setup` to see the address and the admin password.
5. Wait about five minutes for the first start. Run `docker compose logs -f bootstrap` to follow
   the bootstrap step. The step ends with `[bootstrap] done`.

| Setting in `.env` | What the setting does |
| --- | --- |
| `DOMAIN` | The address, for example `coder.example.com`. Without it, the setup uses `<ip>.sslip.io`, as in craft-vscode. |
| `ADMIN_EMAIL` | The admin's email address, for signing in. The default is `admin@example.com`. |
| `ADMIN_PASSWORD` | The admin's password on the first start. Without it, the setup makes one and prints it in the `setup` log. Later changes happen in Coder, under **Account** > **Security**. |
| `ACME_EMAIL` | An email address for Let's Encrypt's certificate notices. |
| `CODER_*` | Any [Coder server setting](https://coder.com/docs/reference/cli/server). `.env.example` shows the GitHub and OIDC settings. |

The Coder server needs the Docker socket, because Coder starts each workspace as a container.
Anyone who can edit templates in Coder can therefore control the server's Docker. By default,
only the admin can edit templates.

### Helm chart (Kubernetes)

The chart in [charts/craft-coder](charts/craft-coder) runs Coder, its Postgres database, the
relay, the apps and a small Caddy front. The front sends `/relay/` to the relay and
everything else to Coder. Workspaces run as pods in the same namespace.

```sh
helm install craft oci://ghcr.io/hayone1/charts/craft-coder \
  --set host=coder.example.com \
  --set ingress.enabled=true --set ingress.className=nginx \
  --set 'ingress.tls[0].secretName=coder-tls' --set 'ingress.tls[0].hosts[0]=coder.example.com'
```

A job runs after each install and upgrade, and makes the server ready. Follow the job with
`kubectl logs -f job/craft-craft-coder-bootstrap`. Read the admin password with
`kubectl get secret craft-craft-coder -o jsonpath='{.data.admin-password}' | base64 -d`.

| Value | What the value does |
| --- | --- |
| `host` | The address without `https://`, for example `coder.example.com`. |
| `publicUrl` | The full address, when the address is not `https://<host>`. |
| `wildcardHost` | Optional, for example `*.coder.example.com`. With a wildcard host, VS Code gets its own subdomain in each workspace, which keeps VS Code apart from Coder's own pages. The wildcard host needs a wildcard DNS record and a wildcard certificate. |
| `admin.*` | The admin's username, email, first password and workspace name. |
| `coder.env` | More Coder settings, for example GitHub or OIDC sign-in. `values.yaml` shows examples. |
| `workspaces.image` | The workspace image. The default is `hayone/craft-code:workspace`. |
| `workspaces.storageClass` | The StorageClass of each home volume. Empty: the cluster's default. |
| `postgres.*` | The built-in database, or `enabled=false` with `externalUrl` for a database of your own. |
| `ingress.*`, `httpRoute.*` | An Ingress or a Gateway API HTTPRoute for `host` and `wildcardHost`. |

[values.yaml](charts/craft-coder/values.yaml) lists every value with an explanation.

### Sign-in

Every person signs in to Coder with their own account. The admin has three ways to give people
accounts:

- **Coder passwords.** The admin adds each person under **Admin settings** > **Users**.
- **GitHub.** Create an OAuth app on GitHub with the callback URL
  `https://<address>/api/v2/users/oauth2/github/callback`. Then set `CODER_OAUTH2_GITHUB_CLIENT_ID`,
  `CODER_OAUTH2_GITHUB_CLIENT_SECRET` and `CODER_OAUTH2_GITHUB_ALLOW_SIGNUPS=true`. Set
  `CODER_OAUTH2_GITHUB_ALLOWED_ORGS` too, because without it any GitHub user could sign up.
- **OpenID Connect** (Google, Microsoft Entra ID, Keycloak, Authentik and others). Set
  `CODER_OIDC_ISSUER_URL`, `CODER_OIDC_CLIENT_ID` and `CODER_OIDC_CLIENT_SECRET`. The redirect
  URL is `https://<address>/api/v2/users/oidc/callback`. Set `CODER_OIDC_EMAIL_DOMAIN` to limit
  sign-up to your company's email domain.

With Docker Compose, put the settings in `.env` and run `docker compose up -d` again. With Helm,
put the settings in `coder.env`.

## Pick the apps

Every deploy runs all eight craft apps unless you choose fewer. An app that you leave out isn't
downloaded or started, and the Craft Apps extension in VS Code doesn't list it. Fewer apps use
less disk space and less memory on the server.

| Deploy | How to pick the apps |
| --- | --- |
| Docker Compose and Hostinger | Set `PHOTOCRAFT=off` to leave PhotoCraft out. The same works with `VECTORCRAFT`, `LIGHTCRAFT`, `FILMCRAFT`, `EFFECTCRAFT`, `WORDCRAFT`, `GRIDCRAFT` and `DECKCRAFT`. On Hostinger, add the setting under **Environment variables** before you deploy. |
| Helm (both charts) | Set `apps.names` to the apps you want, in the order the extension lists them, for example `--set "apps.names={photocraft,filmcraft}"`. |
| Railway | Set the variable `CRAFT_APPS` to the apps you want, comma separated, for example `photocraft,filmcraft`. The container keeps all eight app pages, but the extension lists only these apps. |
| Vercel and Netlify | Change `CRAFT_APPS` on the deploy page, for example to `photocraft,filmcraft`. The site then has only these apps. |

At least one app must stay on. With Docker Compose, the `setup` container stops with the message
"every app is off" when you turn off every app.

A change takes effect at the next start. With Docker Compose, run `docker compose up -d` again.
Docker Compose doesn't stop an app that already runs when you turn the app off, so remove it
with `docker compose rm -sf photocraft` (use the name of the app). With craft-coder, the next
start also updates the template. Each workspace sees the new list after its owner presses
**Update** in Coder.

## Vercel and Netlify

Vercel and Netlify serve files and short functions. They can't run a container that stays on,
and they can't hold the WebSocket connections that the relay needs. So these two buttons deploy
only the app pages, without VS Code and without the relay.

The static site is useful in two cases:

- People can use the apps in a browser tab. The files that the apps open stay on the person's
  device.
- VS Code on your own computer can show the apps. Install
  [Craft Apps](https://github.com/hayone1/craft-vscode) and set `craft.appUrl` to the site's
  address, for example `https://craft-apps.vercel.app`. For Claude Code to drive the apps, the
  extension also needs a relay. Use the relay of a craft-vscode studio that you deployed with
  another button: set `craft.relayUrl` to `https://<studio address>/relay` and set the relay token
  with **Craft: Set the Relay Token**. The relay token is `STUDIO_MINT_TOKEN` in the studio's
  `/home/coder/.craft-studio/secrets.env`.

The build (`node static/build.mjs`) downloads the app pages from the `hayone/<app>:remote` images
on Docker Hub, so the build needs no Docker. Set `EMBED_ORIGINS` in the host's environment
settings to choose which editors may frame the apps, and `CRAFT_APPS` to choose the apps. The default is `vscode-webview://*`, which
is VS Code on the desktop.

## Limits

- **HTTPS is needed.** Browsers run VS Code's panels only on `https://` addresses or on
  `localhost`. Every deploy option here gives HTTPS, except a plain `docker run` on a server.
- **The app pages share the editor's address.** code-server shows each app through its port
  proxy (`/proxy/<port>/`), so the apps and VS Code have the same origin.
- **craft-coder without a wildcard host serves VS Code under Coder's own address.** Coder then
  shows VS Code on a path such as `/@admin/studio.main/apps/code-server/`. Coder warns that a page
  on a path can read Coder's own pages. Set `wildcardHost` in the Helm chart for a separate
  subdomain. The Compose file has no wildcard option yet, because a wildcard certificate needs a
  DNS provider's API.
- **VectorCraft is large.** The VectorCraft page has a 98 MB WebAssembly file. Vercel refuses
  files of 100 MB or more, so a bigger VectorCraft release would break the Vercel build until the
  build splits the file.
- **The hosts cost money.** Railway, Render and Hostinger need a paid plan for a volume or a VPS.
  On Railway, use the Hobby plan or higher. The free trial gives a service 1 GB of memory and a
  500 MB volume, which is too little: Railway stops the studio when it runs out of memory, and
  the extensions don't fit on the volume. The studio prints a warning in its log when the memory
  limit is under 2 GB or less than 1 GB of the home volume is free.
  A craft-vscode studio needs about 1 GB of memory when idle and 2 to 4 GB while Claude Code
  works.

## How the repository is tested

The GitHub Action in [.github/workflows/ci.yml](.github/workflows/ci.yml) checks every deploy
option on each change:

- The static site is built, and the job checks that each app has its page and its editor
  settings.
- Each Helm chart is linted, rendered in several shapes, and installed into a
  [kind](https://kind.sigs.k8s.io) cluster. For craft-coder, the job waits for the bootstrap job,
  signs in as the admin, waits for the admin's workspace, and checks that the workspace reaches the
  apps and the relay. An upgrade must then change nothing.
- Each Compose file runs on the runner with `DOMAIN=localhost`, with the same checks.
- Terraform checks the format of both craft-coder templates and validates them.

The image itself is built and tested in
[hayone1/Docker_Images](https://github.com/hayone1/Docker_Images/tree/main/craft-code).

## License

MIT
