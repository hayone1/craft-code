# Craft Code

Craft Code puts the storytold [craft apps](https://getartcraft.com/apps) inside VS Code, in your web
browser. The craft apps are PhotoCraft, VectorCraft, LightCraft, FilmCraft, EffectCraft, WordCraft,
GridCraft and DeckCraft. Craft Code gives you two big benefits:

1. You can use a powerful tablet or iPad to run the apps. The apps are built with WebAssembly, so
   the apps run on your own device inside the browser.
2. You can work with all the apps from one AI agent session in VS Code. Claude Code comes already
   installed, and Claude Code can draw, edit and save in each app while you watch.

You deploy Craft Code once to a host, such as Railway or your own server. After the deploy, you
open the web address that the host gives you, sign in, and click an app. The app opens in a VS Code
editor tab.

In this README, a **workspace** means one VS Code that runs on the host, with its own files and
its own settings. You reach your workspace from any browser.

## Choose an option

This repository gives you two ways to deploy Craft Code. Pick the way that fits the number of
people who will use Craft Code.

| Option | Who the option is for | How people sign in | Where you can deploy the option |
| --- | --- | --- | --- |
| [craft-vscode](#craft-vscode-one-person) | One person | One password | Railway, Render, Hostinger, your own server, Kubernetes |
| [craft-coder](#craft-coder-a-team) | A team | Each person has an account, and can also sign in with GitHub or a company account | Hostinger, your own server, Kubernetes |

### Deploy buttons for craft-vscode (one person)

| Host | Button | What the host runs |
| --- | --- | --- |
| Railway | [![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/craft-vs-code) | One workspace in one container, with a volume for your files and an HTTPS address. |
| Render | [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/hayone1/craft-code) | One workspace in one container, with a disk for your files and an HTTPS address. |
| Hostinger | [![Deploy on Hostinger](https://assets.hostinger.com/vps/deploy.svg)](https://www.hostinger.com/docker-hosting?compose_url=https://raw.githubusercontent.com/hayone1/craft-code/main/vscode/docker-compose.yml) | A virtual private server (VPS) that runs [vscode/docker-compose.yml](vscode/docker-compose.yml), with an HTTPS address. |
| Vercel | [![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Fhayone1%2Fcraft-code&project-name=craft-apps&env=CRAFT_APPS&envDescription=The%20craft%20apps%20to%20deploy%2C%20comma%20separated&envDefaults=%7B%22CRAFT_APPS%22%3A%22photocraft%2Cvectorcraft%2Clightcraft%2Cfilmcraft%2Ceffectcraft%2Cwordcraft%2Cgridcraft%2Cdeckcraft%22%7D) | The app pages only, without VS Code. See [Vercel and Netlify](#vercel-and-netlify). |
| Netlify | [![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/hayone1/craft-code) | The app pages only, without VS Code. See [Vercel and Netlify](#vercel-and-netlify). |

### Deploy buttons for craft-coder (a team)

| Host | Button | What the host runs |
| --- | --- | --- |
| Hostinger | [![Deploy on Hostinger](https://assets.hostinger.com/vps/deploy.svg)](https://www.hostinger.com/docker-hosting?compose_url=https://raw.githubusercontent.com/hayone1/craft-code/main/coder/docker-compose.yml) | A VPS that runs [coder/docker-compose.yml](coder/docker-compose.yml), with an HTTPS address. |

craft-coder has only one button. craft-coder starts a new container for each person's workspace,
and Railway, Render, Vercel and Netlify don't let an app start new containers. So craft-coder
needs a server with Docker, such as a Hostinger VPS, or a Kubernetes cluster.

## craft-vscode: one person

craft-vscode gives one person one workspace. Everything runs together: VS Code, Claude Code, the
craft apps, and a small server called the relay. The relay passes messages between the apps and
Claude Code, so that Claude Code can control the apps. A password protects the workspace.

### Open your workspace

These steps work for every craft-vscode host.

1. Wait until the host shows that the deploy has finished. The first start takes a few minutes,
   because the workspace downloads the newest Claude Code and Craft Apps extensions. Later starts
   are faster.
2. Open the web address that the host gives you, for example
   `https://craft-vscode-production.up.railway.app`.
3. Type the password. The next section, [Find the password](#find-the-password), says where each
   host shows the password.
4. Click the **Craft** icon in the bar on the left side of VS Code. A list of the craft apps opens.
5. Click an app, for example **VectorCraft**. VectorCraft opens in an editor tab.
6. Click the Claude icon at the top right of the editor, and sign in with your Claude account.
7. Ask Claude to work in the app. For example, type "Draw a gold star in VectorCraft and save it as
   star.svg in the project".

Your files live in the folder `project`, which VS Code opens when you sign in.

### Find the password

The workspace asks for a password, because anyone who signs in can use VS Code and its terminal.

- **Railway** makes a random password when you deploy. Open the service, then **Variables**, and
  copy `PASSWORD`.
- **Render** makes a random password when you deploy. Open the service, then **Environment**, and
  copy `PASSWORD`.
- **Hostinger** and your own server: you can set `PASSWORD` yourself before you deploy. If you
  leave `PASSWORD` empty, the workspace makes a password on the first start and writes the
  password in its log. Run `docker compose logs studio | grep Password` to read the password.
  `studio` is the name of the container that runs VS Code.

To change the password, change the `PASSWORD` setting on the host, and restart the workspace.

### Docker Compose

The file [vscode/docker-compose.yml](vscode/docker-compose.yml) runs craft-vscode on your own
server, with an HTTPS certificate from Let's Encrypt. The Hostinger button uses the same file. The
server needs Docker, ports 80 and 443 open, and at least 2 GB of memory.

1. Clone this repository on the server, and open the `vscode` folder.
2. Copy `.env.example` to `.env`. Fill in the settings from the table below. Every setting is
   optional.
3. Run `docker compose up -d`.
4. Run `docker compose logs setup`. The log shows the address of your workspace, for example
   `https://203-0-113-7.sslip.io`.
5. Open the address, and sign in with the password.

| Setting in `.env` | What the setting does |
| --- | --- |
| `DOMAIN` | The address of your workspace, for example `code.example.com`. First create a DNS record that points the name at the server, because Let's Encrypt checks the name before Let's Encrypt gives a certificate. If you leave `DOMAIN` empty, the address is the server's IP address followed by `.sslip.io`. The free [sslip.io](https://sslip.io) service turns such a name back into the IP address, so you don't need to set up DNS. |
| `PASSWORD` | The password for signing in. If you leave `PASSWORD` empty, the workspace makes a password and writes the password in its log. |
| `ACME_EMAIL` | Your email address. Let's Encrypt sends a message to this address before a certificate runs out. |

The Compose file runs each part in its own container: Caddy for HTTPS, VS Code (the container
`studio`), the relay and the apps. A small container called `setup` runs first at every start.
The `setup` container finds the address and makes the relay's secret keys. Your files stay in the
Docker volume `home`.

To update every part to the newest version, run `docker compose pull && docker compose up -d`.

### Helm chart (Kubernetes)

The chart in [charts/craft-vscode](charts/craft-vscode) runs craft-vscode in a Kubernetes cluster.
VS Code, the relay and each app run in their own pods. The chart needs the address that you will
open, and an Ingress or a Gateway API route that sends the address to VS Code.

```sh
helm install craft-vscode oci://ghcr.io/hayone1/charts/craft-vscode \
  --set host=code.example.com \
  --set ingress.enabled=true --set ingress.className=nginx \
  --set 'ingress.tls[0].secretName=code-tls' --set 'ingress.tls[0].hosts[0]=code.example.com'
```

The chart makes a password on the first install and keeps the same password after each upgrade.
To read the password, run
`kubectl get secret craft-vscode -o jsonpath='{.data.password}' | base64 -d`.

| Value | What the value does |
| --- | --- |
| `host` | The address without `https://`, for example `code.example.com`. |
| `publicUrl` | The full address, if the address is not `https://<host>`. For a test with `kubectl port-forward`, use `http://localhost:8080`. |
| `auth.mode` | `password` (the default) or `none`. Use `none` only when another sign-in, such as oauth2-proxy, already protects the address. |
| `auth.password` | A password of your own. If you leave the value empty, the chart makes a password. |
| `ingress.*` | An Ingress for `host`. The default annotations stop ingress-nginx from closing the app connections after 60 seconds. |
| `httpRoute.*` | A Gateway API HTTPRoute for `host`, which you can use instead of an Ingress. |
| `studio.persistence.*` | The volume for your files in `/home/coder`. The volume is 10 GB by default. |
| `apps.enabled`, `relay.enabled` | Set both values to `false` to run every part in the VS Code pod. |

The file [values.yaml](charts/craft-vscode/values.yaml) explains every value.

### Plain Docker

To try craft-vscode on your own computer, run this command:

```sh
docker run -d -p 8080:8080 -v craft-home:/home/coder -e PASSWORD=choose-a-password hayone/craft-code
```

Then open `http://localhost:8080` and sign in with the password from the command. The
[image README](https://github.com/hayone1/Docker_Images/tree/main/craft-code) lists every setting
of the image.

## craft-coder: a team

craft-coder runs a [Coder](https://coder.com) server. Coder is a server that gives each person on a
team an account and a workspace of their own. Each workspace has VS Code, Claude Code and the
craft apps, and a home folder that only its owner uses. The relay and the app pages run once, next
to Coder, and every workspace shares the relay and the app pages.

The first start sets up Coder for you, so nobody has to set up Coder by hand:

1. A setup step called the bootstrap creates the admin account.
2. The bootstrap adds a Coder template called `craft`. A Coder template describes what each new
   workspace contains.
3. The bootstrap creates and starts the admin's first workspace, which is named `studio`.

### Open your workspace

1. Find the address and the admin password. With Docker Compose, run `docker compose logs setup`.
   On Hostinger, open the logs of the `setup` container. On Kubernetes, the message that
   `helm install` prints shows the command that reads the password.
2. Open the address, and sign in as `admin@example.com` (or the email address that you set in
   `ADMIN_EMAIL`) with the admin password.
3. Open the workspace `studio`, and click **code-server**. VS Code opens in a new tab.
4. Follow steps 4 to 7 in craft-vscode's [Open your workspace](#open-your-workspace) to use the
   apps and Claude Code.
5. Add people under **Admin settings** > **Users**, or let people sign in with GitHub or a company
   account (see [Let your team sign in](#let-your-team-sign-in)). Each person then creates their
   own workspace from the `craft` template.

### Docker Compose

The file [coder/docker-compose.yml](coder/docker-compose.yml) runs craft-coder on your own server,
with an HTTPS certificate from Let's Encrypt. The Hostinger button uses the same file. The server
needs Docker, ports 80 and 443 open, and about 2 GB of memory for Coder plus 2 to 4 GB for each
workspace that runs.

1. Clone this repository on the server, and open the `coder` folder.
2. Copy `.env.example` to `.env`. Fill in the settings from the table below. Every setting is
   optional.
3. Run `docker compose up -d`.
4. Run `docker compose logs setup`. The log shows the address and the admin password.
5. Wait about five minutes for the first start. To follow the bootstrap, run
   `docker compose logs -f bootstrap`. The bootstrap is finished when the log shows
   `[bootstrap] done`.

| Setting in `.env` | What the setting does |
| --- | --- |
| `DOMAIN` | The address, for example `coder.example.com`. If you leave `DOMAIN` empty, the address is the server's IP address followed by `.sslip.io`, as in craft-vscode. |
| `ADMIN_EMAIL` | The email address that the admin signs in with. The default is `admin@example.com`. |
| `ADMIN_PASSWORD` | The admin's password for the first start. If you leave `ADMIN_PASSWORD` empty, the setup makes a password and writes the password in the `setup` log. To change the password later, use **Account** > **Security** in Coder. |
| `ACME_EMAIL` | Your email address. Let's Encrypt sends a message to this address before a certificate runs out. |
| `CODER_*` | Any [Coder server setting](https://coder.com/docs/reference/cli/server). The file `.env.example` shows the settings for GitHub and company sign-in. |

The Coder container can use the server's Docker, because Coder starts each workspace as a new
container. So anyone who can edit Coder templates can control Docker on the server. By default,
only the admin can edit Coder templates.

### Helm chart (Kubernetes)

The chart in [charts/craft-coder](charts/craft-coder) runs craft-coder in a Kubernetes cluster. The
chart runs Coder, a Postgres database for Coder, the relay, the apps and a small Caddy server in
front. The Caddy server sends the path `/relay/` to the relay and every other path to Coder. Each
workspace runs as a pod in the same namespace.

```sh
helm install craft-coder oci://ghcr.io/hayone1/charts/craft-coder \
  --set host=coder.example.com \
  --set ingress.enabled=true --set ingress.className=nginx \
  --set 'ingress.tls[0].secretName=coder-tls' --set 'ingress.tls[0].hosts[0]=coder.example.com'
```

A Kubernetes job runs the bootstrap after each install and each upgrade. To follow the job, run
`kubectl logs -f job/craft-coder-bootstrap`. To read the admin password, run
`kubectl get secret craft-coder -o jsonpath='{.data.admin-password}' | base64 -d`.

| Value | What the value does |
| --- | --- |
| `host` | The address without `https://`, for example `coder.example.com`. |
| `publicUrl` | The full address, if the address is not `https://<host>`. |
| `wildcardHost` | Optional, for example `*.coder.example.com`. With a wildcard host, each workspace shows VS Code on its own subdomain, which keeps VS Code apart from Coder's own pages. A wildcard host needs a wildcard DNS record and a wildcard certificate. |
| `admin.*` | The admin's username, email address, first password and first workspace name. |
| `coder.env` | More Coder settings, for example GitHub or company sign-in. The file `values.yaml` shows examples. |
| `workspaces.image` | The image of each workspace. The default is `hayone/craft-code:workspace`. |
| `workspaces.storageClass` | The StorageClass of each workspace's home volume. If you leave the value empty, the cluster's default StorageClass is used. |
| `postgres.*` | The built-in Postgres database. To use a database of your own, set `enabled=false` and `externalUrl`. |
| `ingress.*`, `httpRoute.*` | An Ingress or a Gateway API HTTPRoute for `host` and `wildcardHost`. |

The file [values.yaml](charts/craft-coder/values.yaml) explains every value.

### Let your team sign in

Every person signs in to Coder with their own account. The admin can give people accounts in three
ways:

- **Coder passwords.** The admin adds each person under **Admin settings** > **Users**.
- **GitHub.** Create an OAuth app on GitHub with the callback URL
  `https://<address>/api/v2/users/oauth2/github/callback`. Then set
  `CODER_OAUTH2_GITHUB_CLIENT_ID`, `CODER_OAUTH2_GITHUB_CLIENT_SECRET` and
  `CODER_OAUTH2_GITHUB_ALLOW_SIGNUPS=true`. Also set `CODER_OAUTH2_GITHUB_ALLOWED_ORGS` to your
  GitHub organization, because without this setting any GitHub user could sign up.
- **A company account through OpenID Connect**, for example Google, Microsoft Entra ID, Keycloak
  or Authentik. Set `CODER_OIDC_ISSUER_URL`, `CODER_OIDC_CLIENT_ID` and
  `CODER_OIDC_CLIENT_SECRET`. The redirect URL is
  `https://<address>/api/v2/users/oidc/callback`. To let only your company sign up, set
  `CODER_OIDC_EMAIL_DOMAIN` to your company's email domain.

With Docker Compose, put the settings in `.env` and run `docker compose up -d` again. With Helm,
put the settings in the value `coder.env`.

## Choose the apps

Every deploy runs all eight craft apps, unless you choose fewer apps. An app that you leave out is
not downloaded and not started, and VS Code doesn't list the app. Fewer apps use less disk space
and less memory on the server.

| Deploy | How to choose the apps |
| --- | --- |
| Docker Compose and Hostinger | Set `PHOTOCRAFT=off` to leave PhotoCraft out. The same works with `VECTORCRAFT`, `LIGHTCRAFT`, `FILMCRAFT`, `EFFECTCRAFT`, `WORDCRAFT`, `GRIDCRAFT` and `DECKCRAFT`. On Hostinger, add the setting under **Environment variables** before you deploy. |
| Helm (both charts) | Set `apps.names` to the apps that you want, in the order that VS Code should list the apps. For example, use `--set "apps.names={photocraft,filmcraft}"`. |
| Railway and Render | Set the variable `CRAFT_APPS` to the apps that you want, separated by commas, for example `photocraft,filmcraft`. On Railway, the deploy page shows `CRAFT_APPS` with all eight apps, and you can remove the apps that you don't want. On Render, add `CRAFT_APPS` under **Environment** after the deploy, and the workspace restarts. |
| Vercel and Netlify | Change `CRAFT_APPS` on the deploy page, for example to `photocraft,filmcraft`. The site then has only these apps. |

At least one app must stay on. With Docker Compose, the `setup` container stops with the message
"every app is off" when you turn off every app.

A change takes effect at the next start. With Docker Compose, run `docker compose up -d` again.
Docker Compose doesn't stop an app that already runs when you turn the app off. To remove the app,
run `docker compose rm -sf photocraft`, with the name of the app instead of `photocraft`. With
craft-coder, the next start also updates the `craft` template. Each workspace gets the new list of
apps after its owner presses **Update** in Coder.

Each person can also hide apps in their own VS Code. Open VS Code's settings, search for
`craft.showApps`, and clear the box of each app that you want to hide.

## Vercel and Netlify

Vercel and Netlify host websites. Vercel and Netlify can't run a container that stays on, and
Vercel and Netlify can't keep the long connections that the relay needs. So the Vercel and Netlify
buttons deploy only the app pages, without VS Code and without the relay.

A site with only the app pages is useful in two cases:

- People can use the apps in a normal browser tab. The files that the apps open stay on each
  person's own device.
- VS Code on your own computer can show the apps from the site. Install the
  [Craft Apps](https://github.com/hayone1/craft-vscode) extension, and set `craft.appUrl` to the
  site's address, for example `https://craft-apps.vercel.app`. For Claude Code to control the apps,
  the extension also needs a relay. You can use the relay of a craft-vscode workspace that you
  deployed with another button. Set `craft.relayUrl` to `https://<workspace address>/relay`. Then
  run the command **Craft: Set the Relay Token**, and paste the relay token. The relay token is the
  value of `STUDIO_MINT_TOKEN` in the file `/home/coder/.craft-studio/secrets.env` of that
  workspace.

The build runs `node static/build.mjs`. The build downloads the app pages from the
`hayone/<app>:remote` images on Docker Hub, so the build doesn't need Docker. Two settings change
the build. Set `CRAFT_APPS` to choose the apps. Set `EMBED_ORIGINS` to choose which editors may
show the apps. The default of `EMBED_ORIGINS` is `vscode-webview://*`, which means VS Code on a
desktop computer.

## What Craft Code contains

Both options run the same parts:

| Part | What the part does |
| --- | --- |
| [code-server](https://github.com/coder/code-server) | VS Code in the browser. |
| [Claude Code](https://www.anthropic.com/claude-code) | The AI agent. Each person signs in with their own Claude account. |
| [Craft Apps](https://github.com/hayone1/craft-vscode) | The VS Code extension. The extension opens the apps in editor tabs, and gives Claude Code one MCP server for every open app. MCP (Model Context Protocol) is the way that Claude Code calls the tools of an app. |
| [craft-mcp](https://hub.docker.com/r/hayone/craft-mcp) | The relay. The apps in the browser and Claude Code in VS Code both connect to the relay, and the relay passes their messages along. |
| The app pages (`hayone/<app>:remote`) | The craft apps as web pages. |

The Docker image [`hayone/craft-code`](https://hub.docker.com/r/hayone/craft-code) has two tags. The
tag `vscode` (also called `latest`) is a whole craft-vscode workspace in one container. The tag
`workspace` is the image of each craft-coder workspace.

## Limits

- **Craft Code needs HTTPS.** Browsers show VS Code's editor tabs for the apps only on `https://`
  addresses or on `localhost`. Every deploy option here gives you HTTPS, except a plain
  `docker run` on a server.
- **The apps share VS Code's address.** VS Code shows each app through a path such as
  `/proxy/<port>/`, so the apps and VS Code have the same web origin.
- **craft-coder without a wildcard host shows VS Code on a path of Coder's own address.** The path
  looks like `/@admin/studio.main/apps/code-server/`. Coder warns that a page on such a path can
  read Coder's own pages. To give VS Code its own subdomain, set `wildcardHost` in the Helm chart.
  The Compose file has no wildcard option yet, because a wildcard certificate needs the API of a
  DNS provider.
- **VectorCraft is large.** The VectorCraft page has a WebAssembly file of 98 MB. Vercel refuses
  files of 100 MB or more, so a bigger VectorCraft release would break the Vercel build.
- **The hosts cost money.** Railway, Render and Hostinger need a paid plan for a volume or a VPS.
  On Railway, use the Hobby plan or higher. Railway's free trial gives a service 1 GB of memory
  and a 500 MB volume. A craft-vscode workspace needs about 1 GB of memory with one app open, and
  2 to 4 GB while Claude Code works, so Railway stops the workspace when the memory runs out. The
  extensions also don't fit on a 500 MB volume. The workspace writes a warning in its log when the
  memory limit is under 2 GB, or when less than 1 GB of the volume is free.

## How the repository is tested

The GitHub Action in [.github/workflows/ci.yml](.github/workflows/ci.yml) checks every deploy
option after each change:

- The Action builds the Vercel and Netlify site, and checks that each app has its page and its
  editor settings.
- The Action checks each Helm chart, and installs each chart into a test Kubernetes cluster made
  with [kind](https://kind.sigs.k8s.io). For craft-coder, the Action waits for the bootstrap, signs
  in as the admin, waits for the admin's workspace, and checks that the workspace reaches the apps
  and the relay. A `helm upgrade` with the same values must then change nothing.
- The Action runs each Compose file with `DOMAIN=localhost`, and runs the same checks.
- Terraform checks the format of both Coder templates, and validates both templates.

The Docker image itself is built and tested in
[hayone1/Docker_Images](https://github.com/hayone1/Docker_Images/tree/main/craft-code).

## License

MIT
