# Choose the apps

Every deploy runs all eight craft apps, unless you choose fewer apps. An app that you leave out is
not downloaded and not started, and VS Code doesn't list the app. Fewer apps use less disk space
and less memory on the server.

| Deploy | How to choose the apps |
| --- | --- |
| Docker Compose and Hostinger | Set `PHOTOCRAFT=off` to leave PhotoCraft out. The same works with `VECTORCRAFT`, `LIGHTCRAFT`, `FILMCRAFT`, `EFFECTCRAFT`, `WORDCRAFT`, `GRIDCRAFT` and `DECKCRAFT`. On Hostinger, add the setting under **Environment variables** before you deploy. |
| Helm (both charts) | Set `apps.names` to the apps that you want, in the order that VS Code should list the apps. For example, use `--set "apps.names={photocraft,filmcraft}"`. |
| Railway and Render | Set the variable `CRAFT_APPS` to the apps that you want, separated by commas, for example `photocraft,filmcraft`. On Railway, the deploy page shows `CRAFT_APPS` with all eight apps, and you can remove the apps that you don't want. On Render, add `CRAFT_APPS` under **Environment** after the deploy, and the workspace restarts. |
| Vercel and Netlify | Vercel's deploy page fills `CRAFT_APPS` with all eight apps, and you can remove the apps that you don't want. Netlify's deploy page shows an empty `CRAFT_APPS` field: leave the field empty for all eight apps, or type the apps that you want, for example `photocraft,filmcraft`. To change the apps later, change `CRAFT_APPS` in the site's environment variables, and deploy the site again. |

At least one app must stay on. With Docker Compose, the `setup` container stops with the message
"every app is off" when you turn off every app.

A change takes effect at the next start. With Docker Compose, run `docker compose up -d` again.
Docker Compose doesn't stop an app that already runs when you turn the app off. To remove the app,
run `docker compose rm -sf photocraft`, with the name of the app instead of `photocraft`. With
craft-coder, the next start also updates the `craft` template. Each workspace gets the new list of
apps after its owner presses **Update** in Coder.

Each person can also hide apps in their own VS Code. Open VS Code's settings, search for
`craft.showApps`, and clear the box of each app that you want to hide.
