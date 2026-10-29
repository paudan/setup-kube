#!/usr/bin/env bash
# Deploys the private image registry on its own (namespace docker-registry, https://registry.kube.org via Traefik websecure); independent of the
# fingraph stack. Needs Traefik with the "websecure" entrypoint (infra/k8s/traefik-values.yaml); on the node run
# the script ends with node-setup.sh (sudo) so registry.kube.org resolves and Docker/containerd trust its CA.
# Usage: deploy.sh   (reads REGISTRY_USER / REGISTRY_PASSWORD from .env)
set -euo pipefail

set -a; . ./.env; set +a
: "${REGISTRY_USER:?set in .env}" "${REGISTRY_PASSWORD:?set in .env}"

# bcrypt htpasswd entry, built in memory and never written to disk
HTPASSWD=$(uv run --no-project --with bcrypt python -c "import bcrypt, os; print(os.environ['REGISTRY_USER'] + ':' + bcrypt.hashpw(os.environ['REGISTRY_PASSWORD'].encode(), bcrypt.gensalt(10, prefix=b'2a')).decode())")
kubectl create namespace docker-registry --dry-run=client -o yaml | kubectl apply -f -
kubectl -n docker-registry create secret generic registry-auth --dry-run=client -o yaml \
  --from-literal=htpasswd="$HTPASSWD" | kubectl -n docker-registry apply -f -

kubectl apply -f storage.yaml -f tls.yaml
helm repo add twuni https://twuni.github.io/docker-registry.helm >/dev/null
helm upgrade --install registry twuni/docker-registry --version 3.0.0 -n docker-registry \
  -f values.yaml --wait --timeout 5m
kubectl -n docker-registry wait certificate/docker-registry-tls --for=condition=Ready --timeout=120s
./node-setup.sh
