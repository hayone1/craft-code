# craft-coder: a team

craft-coder runs a [Coder](https://coder.com) server. Coder is a server that gives each person on a
team an account and a workspace of their own. Each workspace has VS Code, Claude Code and the
craft apps, and a home folder that only its owner uses. The relay and the app pages run once, next
to Coder, and every workspace shares the relay and the app pages.

The first start sets up Coder for you, so nobody has to set up Coder by hand:

1. A setup step called the bootstrap creates the admin account.
2. The bootstrap adds a Coder template called `craft`. A Coder template describes what each new
   workspace contains.
3. The bootstrap creates and starts the admin's first workspace, which is named `studio`.

## Open your workspace

1. Find the address and the admin password. With Docker Compose, run `docker compose logs setup`.
   On Hostinger, open the logs of the `setup` container. On Kubernetes, the message that
   `helm install` prints shows the command that reads the password.
2. Open the address, and sign in as `admin@example.com` (or the email address that you set in
   `ADMIN_EMAIL`) with the admin password.
3. Open the workspace `studio`, and click **code-server**. VS Code opens in a new tab.
4. Follow steps 4 to 7 in [Open your workspace in craft-vscode](craft-vscode.md#open-your-workspace) to use the
   apps and Claude Code.
5. Add people under **Admin settings** > **Users**, or let people sign in with GitHub or a company
   account (see [Let your team sign in](#let-your-team-sign-in)). Each person then creates their
   own workspace from the `craft` template.

## Let your team sign in

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
