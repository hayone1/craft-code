# craft-vscode: one person

craft-vscode gives one person one workspace. Everything runs together: VS Code, Claude Code, the
craft apps, and a small server called the relay. The relay passes messages between the apps and
Claude Code, so that Claude Code can control the apps. A password protects the workspace.

## Open your workspace

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

## Find the password

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
