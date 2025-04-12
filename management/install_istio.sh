#!/bin/bash

curl -L https://istio.io/downloadIstio | sh -
# cd istio-1.25.1
export PATH=$pwd/bin:$PATH
echo "source <(istioctl completion bash)" >> ~/.bashrc
istioctl install --set profile=demo --skip-confirmation --set meshConfig.accessLogFile=/dev/stdout
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
{ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.2.1" | kubectl apply -f -; }
kubectl label namespace default istio-injection=enabled
kubectl apply -f samples/addons
kubectl rollout status deployment/kiali -n istio-system

# Add-on tools:
# istioctl dashboard grafana
# istioctl dashboard jaeger
# istioctl dashboard kiali
# istioctl dashboard prometheus
