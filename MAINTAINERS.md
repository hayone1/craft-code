# Maintaining the deploy buttons

Most buttons read this repository directly: Render reads `render.yaml`, Hostinger reads
`docker-compose.yml`, Vercel reads `vercel.json` and Netlify reads `netlify.toml`. The Railway
button is different. The Railway button points to a template that lives in a Railway account, so
the template must be created and published in Railway's dashboard.

## Create the Railway template

1. Sign in at [railway.com](https://railway.com) and open **Workspace settings** > **Templates**.
2. Press **New Template**. Railway opens the template composer.
3. Add a service with **Docker Image** as the source, and type `hayone/craft-studio:latest`.
4. Name the service `craft-studio`.
5. Open the service's **Variables** and add `PASSWORD` with the value `${{secret(24)}}`. Railway
   then makes a new random password for each deploy.
6. Open the service's **Settings**:
   - Under **Networking**, turn on a public HTTP domain for port `8080`. The studio reads the
     domain from `RAILWAY_PUBLIC_DOMAIN`, so no other address setting is needed.
   - Set the health check path to `/healthz`.
7. Right-click the service and add a **Volume** with the mount path `/home/coder`. The volume
   keeps the projects, the extensions and the Claude Code sign-in across restarts.
8. Press **Create**, then **Publish**. Fill in the name `Craft Studio`, a short description and the
   category **AI/ML**.
9. Copy the template's URL, for example `https://railway.com/deploy/AbC123`. Railway picks the code
   at the end.
10. Replace `https://railway.com/deploy/craft-studio` in `README.md` with that URL.

## Check a button after a change

Each host has its own account, so the GitHub Action can't press the buttons. After a change to a
deploy file, deploy once by hand with the button and follow "After the deploy" in `README.md`.

## Publish the Helm chart

Raise `version` in `charts/craft-studio/Chart.yaml`. The `publish-chart` job pushes the new
version to `oci://ghcr.io/hayone1/charts/craft-studio` when the change reaches `main`. The
package is linked to this public repository, so the package is public too, and `helm install`
works without signing in.
