#!/bin/bash
# Runs vscode/docker-compose.yml with DOMAIN=localhost (Caddy then uses its own local certificate) and
# checks each part through https://localhost. Needs ports 80 and 443 free.
set -eu # no pipefail: `curl | grep -q` would fail when grep stops reading early
cd "$(dirname "$0")/../vscode"
# EFFECTCRAFT=off: the test also checks that an app can be left out.
export DOMAIN=localhost PASSWORD=compose-test-password EFFECTCRAFT=off
dc() { docker compose -p craft-vscode-test "$@"; }
trap 'dc logs --tail 40; dc down -v >/dev/null 2>&1 || true' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

dc up -d --quiet-pull
for _ in $(seq 1 150); do
  code=$(curl -ks -o /dev/null -w '%{http_code}' https://localhost/login || true)
  [ "$code" = 200 ] && break
  sleep 2
done
[ "$code" = 200 ] || fail "code-server sign-in page answered $code"
echo "ok: https://localhost/login"

curl -ks https://localhost/healthz | grep -q ok || fail "healthz"
curl -ks https://localhost/relay/healthz | grep -q ok || fail "relay through the studio"
echo "ok: /relay/ reaches craft-mcp"

cookie=$(mktemp)
curl -ks -c "$cookie" -o /dev/null --data-urlencode "password=$PASSWORD" https://localhost/login
grep -q code-server-session "$cookie" || fail "sign-in"
echo "ok: sign-in"

token=$(dc exec -T studio sh -c '. /setup/private.env && printf %s "$MINT_TOKEN"')
session=$(dc exec -T studio curl -fsS -X POST -H "Authorization: Bearer $token" "http://craft-mcp:8080/mint?app=vectorcraft")
echo "$session" | grep -q '"tab":"wss://localhost/relay/' || fail "minted connection: $session"
echo "ok: the studio's relay token mints connections at https://localhost/relay"

for app in photocraft vectorcraft lightcraft filmcraft wordcraft gridcraft deckcraft; do
  dc exec -T studio curl -fsS "http://$app:8080/_embed/config.json" | grep -q '"https://localhost"' || fail "$app editor settings"
done
echo "ok: seven apps answer the studio at https://localhost"

[ -z "$(dc ps -aq effectcraft)" ] || fail "EFFECTCRAFT=off, but effectcraft runs"
dc exec -T studio sh -c 'tr "\0" "\n" </proc/1/environ' | grep -qx 'CRAFT_APPS=photocraft,vectorcraft,lightcraft,filmcraft,wordcraft,gridcraft,deckcraft' ||
  fail "the studio's CRAFT_APPS"
echo "ok: EFFECTCRAFT=off leaves EffectCraft out"

echo PASS
