#!/bin/bash
# Runs coder/docker-compose.yml with DOMAIN=localhost and this checkout as the bootstrap source,
# then checks that the first start made everything ready: the admin, the template, a running
# admin workspace that reaches the apps and the relay, and VS Code through Coder.
# Needs ports 80 and 443 free.
set -eu # no pipefail: `curl | grep -q` would fail when grep stops reading early
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root/coder"
# EFFECTCRAFT=off: the test also checks that an app can be left out.
export DOMAIN=localhost ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=Compose-test-pass-1 EFFECTCRAFT=off
# Until a workspace tag exists on Docker Hub, a test can pass another image.
export WORKSPACE_IMAGE=${WORKSPACE_IMAGE:-}
override=$(mktemp --suffix .yml)
cat > "$override" <<EOF
services:
  setup:
    volumes: ["setup:/setup", "$root:/source:ro"]
EOF
dc() { docker compose -p craft-coder -f docker-compose.yml -f "$override" "$@"; }
cleanup() {
  dc logs --tail 60 setup bootstrap coder || true
  docker ps -a --filter label=coder.owner --format '{{.Names}}' | xargs -r docker logs --tail 60 || true
  docker ps -aq --filter label=coder.owner | xargs -r docker rm -f >/dev/null 2>&1 || true
  docker volume ls -q --filter label=coder.owner | xargs -r docker volume rm >/dev/null 2>&1 || true
  dc down -v >/dev/null 2>&1 || true
}
trap cleanup EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

dc up -d --quiet-pull

# The bootstrap service exits when it is done.
for _ in $(seq 1 300); do
  state=$(dc ps -a --format '{{.State}} {{.ExitCode}}' bootstrap)
  case $state in exited*) break ;; esac
  sleep 2
done
[ "$state" = "exited 0" ] || fail "bootstrap: $state"
echo "ok: bootstrap finished"

curl -ks https://localhost/healthz | grep -q OK || fail "Coder through Caddy"
curl -ks https://localhost/relay/healthz | grep -q ok || fail "relay through Caddy"
echo "ok: Coder and /relay/ through https://localhost"

body=$(printf '{"email":"%s","password":"%s"}' "$ADMIN_EMAIL" "$ADMIN_PASSWORD")
token=$(curl -ksf -H 'Content-Type: application/json' -d "$body" https://localhost/api/v2/users/login | jq -r .session_token)
[ -n "$token" ] || fail "sign-in as the admin"
api() { curl -ksf -H "Coder-Session-Token: $token" "https://localhost/api/v2/$1"; }
echo "ok: the admin signs in"

api templates | jq -e 'any(.[]; .name == "craft")' >/dev/null || fail "template craft"
echo "ok: template craft"

for _ in $(seq 1 300); do
  agent=$(api users/admin/workspace/studio | jq -r '[.latest_build.resources[].agents[]?][0] | "\(.status) \(.lifecycle_state)"')
  [ "$agent" = "connected ready" ] && break
  case $agent in *start_error* | *start_timeout*) fail "workspace agent: $agent" ;; esac
  sleep 2
done
[ "$agent" = "connected ready" ] || fail "workspace agent: $agent"
echo "ok: workspace admin/studio is running and its agent is ready"

ws=$(docker ps --filter label=coder.owner=admin --format '{{.Names}}' | head -1)
[ -n "$ws" ] || fail "workspace container"
inside() { docker exec "$ws" sh -c "$1"; }
inside 'curl -fsS http://photocraft:8080/_embed/config.json' | grep -q '"https://localhost"' || fail "apps from the workspace"
inside 'curl -fsS http://craft-mcp:8080/healthz' | grep -q ok || fail "relay from the workspace"
# The agent gives its env to the processes it starts (code-server), not to the container.
inside 'for p in /proc/[0-9]*; do tr "\0" "\n" <$p/environ 2>/dev/null | grep -q "^CRAFT_RELAY_TOKEN=." && exit 0; done; exit 1' ||
  fail "relay token in the workspace"
echo "ok: the workspace reaches the apps and the relay"

[ -z "$(dc ps -aq effectcraft)" ] || fail "EFFECTCRAFT=off, but effectcraft runs"
inside 'for p in /proc/[0-9]*; do tr "\0" "\n" <$p/environ 2>/dev/null | grep -qx "CRAFT_APPS=photocraft,vectorcraft,lightcraft,filmcraft" && exit 0; done; exit 1' ||
  fail "the workspace's CRAFT_APPS"
echo "ok: EFFECTCRAFT=off leaves EffectCraft out"

for _ in $(seq 1 90); do
  # Coder sets its app cookie through redirects, so follow them with a cookie jar.
  code=$(curl -ksL -c /tmp/app-cookies -b /tmp/app-cookies -o /dev/null -w '%{http_code}' \
    "https://localhost/@admin/studio.main/apps/code-server/?coder_session_token=$token")
  [ "$code" = 200 ] && break
  sleep 2
done
[ "$code" = 200 ] || fail "VS Code through Coder answered $code"
echo "ok: VS Code through Coder"

# The code-server module installs the extensions in the background.
for _ in $(seq 1 90); do
  exts=$(inside 'code-server --list-extensions 2>/dev/null' || true)
  echo "$exts" | grep -qi '^hayone1.craft-vscode$' && echo "$exts" | grep -qi '^anthropic.claude-code$' && break
  sleep 2
done
echo "$exts" | grep -qi '^anthropic.claude-code$' || fail "Claude Code extension missing"
echo "$exts" | grep -qi '^hayone1.craft-vscode$' || fail "Craft Apps extension missing"
echo "ok: Claude Code and Craft Apps are installed"

# A second start changes nothing.
dc up -d --quiet-pull --force-recreate setup bootstrap
for _ in $(seq 1 120); do
  state=$(dc ps -a --format '{{.State}} {{.ExitCode}}' bootstrap)
  case $state in exited*) break ;; esac
  sleep 2
done
[ "$state" = "exited 0" ] || fail "second bootstrap: $state"
dc logs bootstrap | grep -q "is current" || fail "second bootstrap pushed the template again"
[ "$(api templates/"$(api templates | jq -r '.[] | select(.name == "craft") | .id')"/versions | jq length)" = 1 ] ||
  fail "more than one template version"
echo "ok: a second start changes nothing"
echo PASS
