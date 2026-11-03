#!/usr/bin/env bash

set -euo pipefail

# Namespace first, then the operator and its CRDs (Kustomize moves the bundle from "default" to "monitoring")
kubectl apply -f infra/prometheus/namespace.yaml
kubectl apply --server-side -k infra/prometheus/operator
kubectl wait --for=condition=Established crd/prometheuses.monitoring.coreos.com crd/servicemonitors.monitoring.coreos.com --timeout=60s

# The operator only registers the CRDs it finds at startup, so restart it in case it came up before them
kubectl -n monitoring rollout restart deploy/prometheus-operator
kubectl -n monitoring rollout status deploy/prometheus-operator --timeout=120s
kubectl apply -f infra/prometheus/rbac.yaml -f infra/prometheus/prometheus.yaml -f infra/prometheus/servicemonitor-traefik.yaml
kubectl -n monitoring wait prometheus/shared --for=condition=Available --timeout=300s
