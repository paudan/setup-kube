#!/usr/bin/env bash
# Deploys the shared Prometheus (namespace monitoring) on its own; needs the Prometheus Operator and its CRDs in the cluster.
# Usage: deploy.sh
set -euo pipefail

# Add Prometheus Operator CRDs (for the registry Helm chart to create ServiceMonitor for Traefik metrics)
kubectl apply -f https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.94.2/bundle.yaml

kubectl get crd prometheuses.monitoring.coreos.com servicemonitors.monitoring.coreos.com >/dev/null
kubectl apply -f namespace.yaml
kubectl apply -f rbac.yaml -f prometheus.yaml -f servicemonitor-traefik.yaml
kubectl -n monitoring wait prometheus/shared --for=condition=Available --timeout=300s
