#!/bin/bash
# Installs charts/craft-coder into the current Kubernetes cluster (CI: kind) and checks that the
# bootstrap job made everything ready: the admin, the template, and a running admin workspace that
# reaches the apps and the relay. Extra arguments go to `helm install`.
set -eu # no pipefail: `curl | grep -q` would fail when grep stops reading early
cd "$(dirname "$0")/.."
fail() { echo "FAIL: $*" >&2; kubectl get pods -A || true; kubectl logs job/t-craft-coder-bootstrap --tail 80 || true; kubectl logs deploy/t-craft-coder --tail 80 || true; exit 1; }

helm install t charts/craft-coder --set publicUrl=http://localhost:8080 --wait --timeout 20m "$@" ||
  fail "helm install"
kubectl get pods
kubectl wait --for=condition=complete job/t-craft-coder-bootstrap --timeout 5m || fail "bootstrap job"
echo "ok: bootstrap job finished"

kubectl port-forward svc/t-craft-coder-front 8080:8080 >/dev/null 2>&1 &
for _ in $(seq 1 60); do
  curl -fsS http://localhost:8080/healthz >/dev/null 2>&1 && break
  sleep 1
done
curl -fsS http://localhost:8080/healthz | grep -q OK || fail "Coder through the front"
curl -fsS http://localhost:8080/relay/healthz | grep -q ok || fail "relay through the front"
echo "ok: Coder and /relay/ through the front"

pw=$(kubectl get secret t-craft-coder -o jsonpath='{.data.admin-password}' | base64 -d)
body=$(printf '{"email":"admin@example.com","password":"%s"}' "$pw")
token=$(curl -fsS -H 'Content-Type: application/json' -d "$body" http://localhost:8080/api/v2/users/login | jq -r .session_token)
[ -n "$token" ] || fail "sign-in as the admin"
api() { curl -fsS -H "Coder-Session-Token: $token" "http://localhost:8080/api/v2/$1"; }
api templates | jq -e 'any(.[]; .name == "craft")' >/dev/null || fail "template craft"
echo "ok: the admin signs in, template craft exists"

for _ in $(seq 1 450); do
  agent=$(api users/admin/workspace/studio | jq -r '[.latest_build.resources[].agents[]?][0] | "\(.status) \(.lifecycle_state)"')
  [ "$agent" = "connected ready" ] && break
  case $agent in *start_error* | *start_timeout*) fail "workspace agent: $agent" ;; esac
  sleep 2
done
[ "$agent" = "connected ready" ] || fail "workspace agent: $agent"
echo "ok: workspace admin/studio is running and its agent is ready"

pod=$(kubectl get pods -l com.coder.user.username=admin -o name | head -1)
[ -n "$pod" ] || fail "workspace pod"
inside() { kubectl exec "$pod" -- sh -c "$1"; }
inside 'curl -fsS http://t-craft-coder-photocraft.default.svc:8080/_embed/config.json' |
  grep -q '"http://localhost:8080"' || fail "apps from the workspace"
inside 'curl -fsS "$CRAFT_RELAY_URL/healthz"' | grep -q ok || fail "relay from the workspace"
echo "ok: the workspace reaches the apps and the relay"

for _ in $(seq 1 90); do
  code=$(curl -s -o /dev/null -w '%{http_code}' -H "Coder-Session-Token: $token" \
    http://localhost:8080/@admin/studio.main/apps/code-server/)
  [ "$code" = 200 ] && break
  sleep 2
done
[ "$code" = 200 ] || fail "VS Code through Coder answered $code"
echo "ok: VS Code through Coder"

# An upgrade runs the job again, and the job changes nothing.
helm upgrade t charts/craft-coder --reuse-values --wait --timeout 10m || fail "helm upgrade"
kubectl logs job/t-craft-coder-bootstrap | grep -q "is current" || fail "the upgrade pushed the template again"
echo "ok: an upgrade changes nothing"
echo PASS
