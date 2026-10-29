#!/usr/bin/env bash
# Deploy Langfuse instance
set -euo pipefail

# 1. cert-manager (skip if already installed)
helm install cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.20.2 \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true

kubectl wait --for=condition=Established \
  crd/certificates.cert-manager.io crd/issuers.cert-manager.io \
  --timeout=120s

# 2. clickhouse-operator
helm install clickhouse-operator oci://ghcr.io/clickhouse/clickhouse-operator-helm \
  --version 0.0.8 \
  --namespace clickhouse-operator --create-namespace

kubectl wait --for=condition=Established \
  crd/clickhouseclusters.clickhouse.com crd/keeperclusters.clickhouse.com \
  --timeout=120s

kubectl create namespace langfuse
kubectl apply -f secret.yaml -n langfuse
helm install langfuse oci://ghcr.io/langfuse/langfuse-k8s/charts/langfuse \
  --version 2.0.0 \
  --namespace langfuse \
  -f values.yaml
# 4. expose the UI through Traefik (:3000)
kubectl apply -f "$(dirname "$0")/ingress.yaml"
