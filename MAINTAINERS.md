# Maintaining the deploy buttons

Most buttons read this repository directly: Render reads `render.yaml`, the two Hostinger buttons read
`vscode/docker-compose.yml` and `coder/docker-compose.yml`, Vercel reads `vercel.json` and Netlify reads `netlify.toml`. The Railway
button (craft-vscode only) is different. The Railway button points to a template that lives in a Railway account, so
the template must be created and published in Railway's dashboard.

## Create the Railway template

1. Sign in at [railway.com](https://railway.com) and open **Workspace settings** > **Templates**.
2. Press **New Template**. Railway opens the template composer.
3. Add a service with **Docker Image** as the source, and type `hayone/craft-code:vscode`.
4. Name the service `craft-vscode`.
5. Open the service's **Variables** and add `PASSWORD` with the value `${{secret(24)}}`. Railway
   then makes a new random password for each deploy.
   Also add `CRAFT_APPS` with the value
   `photocraft,vectorcraft,lightcraft,filmcraft,effectcraft,wordcraft,gridcraft,deckcraft`.
   People who deploy the template can then remove the apps that they don't want.
   Type each name with no space before or after it. Railway keeps a space that is typed after a
   name, and a setting called `CRAFT_APPS ` (with the space) doesn't reach the extension. The
   image reads such a setting anyway since 2026-11-23, but the template should still be right.
   Add a description to `CRAFT_APPS`, for example "The craft apps to show, comma separated", so
   that people see the variable on the deploy page.
6. Open the service's **Settings**:
   - Under **Networking**, turn on a public HTTP domain for port `8080`. The studio reads the
     domain from `RAILWAY_PUBLIC_DOMAIN`, so no other address setting is needed.
   - Set the health check path to `/healthz`, and the health check timeout to `600` seconds. The
     first start downloads the extensions, which takes a few minutes.
   - Set the restart policy to **Always**, so that Railway starts the studio again after any stop.
7. Right-click the service and add a **Volume** with the mount path `/home/coder`. The volume
   keeps the projects, the extensions and the Claude Code sign-in across restarts. The volume
   needs 5 GB or more, which the Hobby plan gives by default. The trial's 500 MB volume is too
   small for the extensions.
8. Press **Create**, then **Publish**. Fill in the name `Craft VS Code`, a short description and the
   category **AI/ML**.
9. Copy the template's URL. The published template is
   `https://railway.com/deploy/craft-vs-code`, and the Railway button in `README.md` points there.
   If you publish a new template, Railway picks a new code, so put the new URL in `README.md`.

## Check a button after a change

Each host has its own account, so the GitHub Action can't press the buttons. After a change to a
deploy file, deploy once by hand with the button and follow "After the deploy" in `README.md`.

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

## Publish the Helm chart

Raise `version` in `charts/<chart>/Chart.yaml`, where `<chart>` is `craft-vscode` or
`craft-coder`. The `publish-chart` job pushes the new version to
`oci://ghcr.io/hayone1/charts/<chart>` when the change reaches `main`. A chart pushed for the
first time may start as a private package. If `helm install` then asks for a sign-in, open the
package on GitHub (your profile > **Packages**), and set its visibility to public under
**Package settings**.

## The craft-coder bootstrap files

The craft-coder Compose file downloads `charts/craft-coder/files/bootstrap.sh` and the Docker
template from the `main` branch at every start. A change to those files therefore reaches every
Compose server at its next restart. Test such a change with `bash test/coder-compose.sh` or in CI
before merging it.
