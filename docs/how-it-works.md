# How Craft Code works

This page lists the parts that Craft Code is made of, and the limits that you should know about
before you deploy. Both options, craft-vscode and craft-coder, run the same parts:

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
