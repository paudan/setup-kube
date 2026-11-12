#!/usr/bin/env bash
# Bootstraps the stack through Argo CD: prerequisites Argo cannot hold in git (secrets, images), then the root app.
# Usage: deploy.sh (reads credentials from .env; ARGOCD_REPO_KEY = SSH deploy key file, needed only while the repo secret does not exist yet)
set -euo pipefail

A="kubectl -n argocd"
REG=registry.kube.org
SECRET=repo-service
APPNAME=app

set -a; . ./.env; set +a

# Argo reads the manifests from GitHub, so local-only changes would not be deployed
git fetch -q origin main
if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ] || ! git diff --quiet HEAD -- infra; then
  echo "warning: infra/ differs from origin/main; Argo CD deploys only what is pushed" >&2
fi

# Argo CD server behind Traefik: plain HTTP, restart only when the setting changes
if [ "$($A get cm argocd-cmd-params-cm -o jsonpath='{.data.server\.insecure}')" != "true" ]; then
  $A patch cm argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure":"true"}}'
  $A rollout restart deploy/argocd-server
  $A rollout status deploy/argocd-server --timeout=180s
fi
$A apply -f argocd-ingress.yaml

# Git repository: declared in repository.yaml, the SSH deploy key is added once (kept on later applies)
$A apply -f repository.yaml
# ARGOCD_REPO_KEY=.ssh/id_ed25519
if [ -z "$($A get secret $SECRET -o jsonpath='{.data.sshPrivateKey}')" ]; then
  : "${ARGOCD_REPO_KEY:?set ARGOCD_REPO_KEY to the SSH deploy key file (repo secret has no key yet)}"
  python3 -c 'import json, sys; print(json.dumps({"stringData": {"sshPrivateKey": open(sys.argv[1]).read()}}))' "$ARGOCD_REPO_KEY" \
    | $A patch secret $SECRET --type merge --patch-file /dev/stdin
fi

# Cluster-wide services are deployed separately (local-path-provisioner.yaml, Traefik, infra/registry); fail early without them
kubectl get crd ingressroutetcps.traefik.io >/dev/null
kubectl get sc -o jsonpath='{.items[*].metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' | grep -q true
kubectl -n docker-registry get deploy registry >/dev/null

# Prerequisites outside git: namespace, secrets, images
kubectl apply -f namespace.yaml
secrets.sh
echo "$REGISTRY_PASSWORD" | docker login $REG -u "$REGISTRY_USER" --password-stdin

# Root app creates the project and the app
kubectl apply -f root.yaml
until $A get application $APP >/dev/null 2>&1; do sleep 3; done
$A wait application/$APP --for=jsonpath='{.status.health.status}'=Healthy --timeout=900s
$A get applications
