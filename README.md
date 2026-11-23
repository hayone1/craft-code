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
| [craft-vscode](docs/craft-vscode.md) | One person | One password | Railway, Render, Hostinger, your own server, Kubernetes |
| [craft-coder](docs/craft-coder.md) | A team | Each person has an account, and can also sign in with GitHub or a company account | Hostinger, your own server, Kubernetes |

If you want only the apps in a browser tab, without VS Code and without an AI agent, use the
[buttons for the app pages only](#deploy-buttons-for-the-app-pages-only-no-vs-code-no-ai-agent).

### Deploy buttons for craft-vscode (one person)

| Host | Button | What the host runs |
| --- | --- | --- |
| Railway | [![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/craft-vs-code) | One workspace in one container, with a volume for your files and an HTTPS address. |
| Render | [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/hayone1/craft-code) | One workspace in one container, with a disk for your files and an HTTPS address. |
| Hostinger | [![Deploy on Hostinger](https://assets.hostinger.com/vps/deploy.svg)](https://www.hostinger.com/docker-hosting?compose_url=https://raw.githubusercontent.com/hayone1/craft-code/main/vscode/docker-compose.yml) | A virtual private server (VPS) that runs [vscode/docker-compose.yml](vscode/docker-compose.yml), with an HTTPS address. |

The Hostinger button opens Hostinger's Docker hosting page, which shows the prices of the VPS
plans. Choose a plan and pay. When the new VPS is ready, Hostinger opens its Docker Manager with the
Craft Code file already filled in. If you already have a Hostinger VPS, follow
[Use a Hostinger VPS that you already have](docs/craft-vscode-own-server.md#use-a-hostinger-vps-that-you-already-have)
instead.

### Deploy buttons for craft-coder (a team)

| Host | Button | What the host runs |
| --- | --- | --- |
| Hostinger | [![Deploy on Hostinger](https://assets.hostinger.com/vps/deploy.svg)](https://www.hostinger.com/docker-hosting?compose_url=https://raw.githubusercontent.com/hayone1/craft-code/main/coder/docker-compose.yml) | A VPS that runs [coder/docker-compose.yml](coder/docker-compose.yml), with an HTTPS address. |

The Hostinger button works the same way as the craft-vscode button. If you already have a Hostinger
VPS, follow
[Use a Hostinger VPS that you already have](docs/craft-coder-own-server.md#use-a-hostinger-vps-that-you-already-have).

craft-coder has only one button. craft-coder starts a new container for each person's workspace,
and Railway and Render don't let an app start new containers. So craft-coder
needs a server with Docker, such as a Hostinger VPS, or a Kubernetes cluster.

### Deploy buttons for the app pages only (no VS Code, no AI agent)

Vercel and Netlify host websites, but Vercel and Netlify can't run VS Code or the relay. So these
two buttons deploy only the craft apps as web pages. You open each app in a browser tab, and the
files that an app opens stay on your own device. Claude Code isn't included. The page
[Vercel and Netlify](docs/vercel-netlify.md) explains how VS Code on your own computer can still use
the apps from such a site.

| Host | Button | What the host runs |
| --- | --- | --- |
| Vercel | [![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Fhayone1%2Fcraft-code&project-name=craft-apps&env=CRAFT_APPS&envDescription=The%20craft%20apps%20to%20deploy%2C%20with%20commas%20between%20them.%20All%20the%20apps%3A%20photocraft%2Cvectorcraft%2Clightcraft%2Cfilmcraft%2Ceffectcraft%2Cwordcraft%2Cgridcraft%2Cdeckcraft&envDefaults=%7B%22CRAFT_APPS%22%3A%22photocraft%2Cvectorcraft%2Clightcraft%2Cfilmcraft%2Ceffectcraft%2Cwordcraft%2Cgridcraft%2Cdeckcraft%22%7D) | A website with the app pages, for example `https://craft-apps.vercel.app/photocraft/`. |
| Netlify | [![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/hayone1/craft-code) | A website with the app pages, for example `https://craft-apps.netlify.app/photocraft/`. |

## After the deploy

1. Open the web address that the host gives you, and sign in. For craft-vscode, the page
   [Find the password](docs/craft-vscode.md#find-the-password) says where each host shows the
   password. For craft-coder, sign in as the admin, as [Open your workspace](docs/craft-coder.md#open-your-workspace)
   describes.
2. Click the **Craft** icon in the bar on the left side of VS Code, and click an app.
3. Click the Claude icon at the top right of the editor, and sign in with your Claude account.
4. Ask Claude to work in the app, for example "Draw a gold star in VectorCraft and save it as
   star.svg in the project".

The first start takes a few minutes, because the workspace downloads the newest extensions. On
Railway, use the Hobby plan or higher, because the free trial gives too little memory for Craft
Code.

## Guides

| Guide | What the guide explains |
| --- | --- |
| [craft-vscode: one person](docs/craft-vscode.md) | How to open your workspace and find the password after a deploy. |
| [Run craft-vscode on your own server](docs/craft-vscode-own-server.md) | Docker Compose, the Helm chart for Kubernetes, and plain Docker. |
| [craft-coder: a team](docs/craft-coder.md) | How the first start sets up Coder, how to open your workspace, and how your team signs in. |
| [Run craft-coder on your own server](docs/craft-coder-own-server.md) | Docker Compose and the Helm chart for Kubernetes. |
| [Choose the apps](docs/choose-apps.md) | How to deploy fewer than eight apps, or hide apps in VS Code. |
| [Vercel and Netlify](docs/vercel-netlify.md) | What the app-pages-only site does, and how to use the site from VS Code on your own computer. |
| [How Craft Code works](docs/how-it-works.md) | The parts inside Craft Code, and the limits to know before you deploy. |

People who change this repository can read [MAINTAINERS.md](MAINTAINERS.md).

## License

MIT
