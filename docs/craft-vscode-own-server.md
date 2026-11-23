# Run craft-vscode on your own server

This page shows three ways to run craft-vscode on a machine that you control: Docker Compose on a
server, a Helm chart on Kubernetes, and a single `docker run` command on your own computer. For a
deploy with one click, use a button in the [README](../README.md#deploy-buttons-for-craft-vscode-one-person)
instead. After the deploy, follow [Open your workspace](craft-vscode.md#open-your-workspace).

## Docker Compose

The file [vscode/docker-compose.yml](../vscode/docker-compose.yml) runs craft-vscode on your own
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

## Helm chart (Kubernetes)

The chart in [charts/craft-vscode](../charts/craft-vscode) runs craft-vscode in a Kubernetes cluster.
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

The file [values.yaml](../charts/craft-vscode/values.yaml) explains every value.

## Plain Docker

To try craft-vscode on your own computer, run this command:

```sh
docker run -d -p 8080:8080 -v craft-home:/home/coder -e PASSWORD=choose-a-password hayone/craft-code
```

Then open `http://localhost:8080` and sign in with the password from the command. The
[image README](https://github.com/hayone1/Docker_Images/tree/main/craft-code) lists every setting
of the image.
