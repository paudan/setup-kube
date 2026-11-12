#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")/../.."
K="kubectl -n app"

set -a; . ./.env; set +a

# Secret with composed connection strings; never written to disk
$K create secret generic app-env --dry-run=client -o yaml \
  --from-literal=GEMINI_API_KEY="${GEMINI_API_KEY:-}"

# Pull secret for the private registry (infra/registry), referenced by the default ServiceAccount
: "${REGISTRY_USER:?set in .env}" "${REGISTRY_PASSWORD:?set in .env}"
$K create secret docker-registry registry-pull --dry-run=client -o yaml \
  --docker-server=registry.kube.org --docker-username="$REGISTRY_USER" --docker-password="$REGISTRY_PASSWORD" | $K apply -f -
