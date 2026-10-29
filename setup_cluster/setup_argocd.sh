#!/bin/bash

# Ensure that Traefik is setup
helm repo add traefik https://traefik.github.io/charts >/dev/null
helm upgrade --install traefik traefik/traefik --version 41.7.1 -n traefik --create-namespace \
  -f traefik-values.yaml --wait --timeout 5m

kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure":"true"}}' 
kubectl -n argocd rollout restart deployment argocd-server 
kubectl -n argocd rollout status deployment argocd-server --timeout=120s

# Create the Ingress
kubectl apply -n argocd -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: argocd
spec:
  ingressClassName: traefik
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  name: http
EOF

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
