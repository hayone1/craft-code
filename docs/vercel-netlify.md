# Vercel and Netlify

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
