#!/bin/sh
# craft-coder bootstrap: makes a fresh Coder server ready to use. The Docker Compose file runs this
# script at every start, and the Helm chart runs it after every install and upgrade. Every step is
# skipped when it is already done, so a second run changes nothing.
#
#   1. Create the first user (the admin), unless Coder already has users.
#   2. Push the template, unless Coder already has this exact version.
#   3. On the template's first push only, create and start a workspace for the admin.
#
# Needs curl and jq (Alpine: apk add curl jq). Settings, as environment variables:
#   CODER_URL         The Coder server, as this script reaches it, e.g. http://coder:7080.
#   ADMIN_USERNAME    Default: admin.
#   ADMIN_EMAIL       Default: admin@example.com.
#   ADMIN_PASSWORD    Needed.
#   TEMPLATE_NAME     Default: craft.
#   TEMPLATE_DIR      The template folder, with main.tf.
#   VARIABLES_FILE    A YAML file with the template's variables (optional).
#   WORKSPACE_NAME    The admin's workspace. Default: studio. Empty: no workspace.
set -eu

: "${CODER_URL:?}" "${ADMIN_PASSWORD:?}" "${TEMPLATE_DIR:?}"
ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@example.com}
TEMPLATE_NAME=${TEMPLATE_NAME:-craft}
WORKSPACE_NAME=${WORKSPACE_NAME-studio}
CODER_URL=${CODER_URL%/}
export CODER_CONFIG_DIR=/tmp/coder-config
say() { printf '[bootstrap] %s\n' "$*"; }

say "waiting for $CODER_URL"
i=0
until curl -fsS -o /dev/null "$CODER_URL/healthz"; do
  i=$((i + 1))
  [ "$i" -lt 300 ] || { say "Coder didn't answer in 10 minutes"; exit 1; }
  sleep 2
done

# The Coder server serves its own command-line tool, so the versions always match.
case $(uname -m) in
  x86_64) arch=amd64 ;;
  aarch64 | arm64) arch=arm64 ;;
  *) arch=armv7 ;;
esac
curl -fsS -o /tmp/coder "$CODER_URL/bin/coder-linux-$arch"
chmod +x /tmp/coder
coder() { /tmp/coder "$@"; }

if [ "$(curl -s -o /dev/null -w '%{http_code}' "$CODER_URL/api/v2/users/first")" = 404 ]; then
  say "creating the first user, $ADMIN_USERNAME"
  coder login "$CODER_URL" --first-user-username "$ADMIN_USERNAME" --first-user-email "$ADMIN_EMAIL" \
    --first-user-password "$ADMIN_PASSWORD" --first-user-full-name "Admin" --first-user-trial=false >/dev/null
else
  body=$(jq -n --arg e "$ADMIN_EMAIL" --arg p "$ADMIN_PASSWORD" '{email: $e, password: $p}')
  token=$(curl -fsS -X POST -H 'Content-Type: application/json' -d "$body" "$CODER_URL/api/v2/users/login" |
    jq -r .session_token) || token=
  if [ -z "$token" ]; then
    # The admin changed the password or the email in Coder. Nothing here needs doing then.
    say "can't sign in as $ADMIN_EMAIL any more; leaving the server as it is"
    exit 0
  fi
  export CODER_URL CODER_SESSION_TOKEN="$token"
fi

# The version name is a hash of the template and its variables, so an unchanged template is
# not pushed again.
hash=$( (cat "$TEMPLATE_DIR"/*.tf; [ -n "${VARIABLES_FILE:-}" ] && cat "$VARIABLES_FILE") | sha256sum | cut -c1-12)
if coder templates versions list "$TEMPLATE_NAME" -o json >/tmp/versions.json 2>/dev/null; then
  new_template=false
else
  new_template=true
fi
if [ "$new_template" = false ] && jq -e --arg h "$hash" 'any(.[]; .name == $h)' /tmp/versions.json >/dev/null; then
  say "template $TEMPLATE_NAME is current ($hash)"
else
  say "pushing template $TEMPLATE_NAME ($hash)"
  # coder copies the folder, so a read-only mount works.
  cp -r "$TEMPLATE_DIR" /tmp/template
  set -- --directory /tmp/template --name "$hash" --yes
  [ -n "${VARIABLES_FILE:-}" ] && set -- "$@" --variables-file "$VARIABLES_FILE"
  coder templates push "$TEMPLATE_NAME" "$@"
fi

if [ "$new_template" = true ] && [ -n "$WORKSPACE_NAME" ]; then
  say "creating the workspace $ADMIN_USERNAME/$WORKSPACE_NAME"
  coder create "$ADMIN_USERNAME/$WORKSPACE_NAME" --template "$TEMPLATE_NAME" --use-parameter-defaults --yes ||
    say "couldn't create the workspace; create it in Coder's dashboard"
fi
say "done"
