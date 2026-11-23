# Run craft-coder on your own server

This page shows two ways to run craft-coder on machines that you control: Docker Compose on a
server, and a Helm chart on Kubernetes. The Hostinger button in the
[README](../README.md#deploy-buttons-for-craft-coder-a-team) uses the same Docker Compose file. After
the deploy, follow [Open your workspace](craft-coder.md#open-your-workspace).

## Docker Compose

The file [coder/docker-compose.yml](../coder/docker-compose.yml) runs craft-coder on your own server,
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
| `DOMAIN` | The address, for example `coder.example.com`. If you leave `DOMAIN` empty, the address is the server's IP address followed by `.sslip.io`, as in [craft-vscode](craft-vscode-own-server.md#docker-compose). |
| `ADMIN_EMAIL` | The email address that the admin signs in with. The default is `admin@example.com`. |
| `ADMIN_PASSWORD` | The admin's password for the first start. If you leave `ADMIN_PASSWORD` empty, the setup makes a password and writes the password in the `setup` log. To change the password later, use **Account** > **Security** in Coder. |
| `ACME_EMAIL` | Your email address. Let's Encrypt sends a message to this address before a certificate runs out. |
| `CODER_*` | Any [Coder server setting](https://coder.com/docs/reference/cli/server). The file `.env.example` shows the settings for GitHub and company sign-in. |

The Coder container can use the server's Docker, because Coder starts each workspace as a new
container. So anyone who can edit Coder templates can control Docker on the server. By default,
only the admin can edit Coder templates.

## Helm chart (Kubernetes)

The chart in [charts/craft-coder](../charts/craft-coder) runs craft-coder in a Kubernetes cluster. The
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

The file [values.yaml](../charts/craft-coder/values.yaml) explains every value.
