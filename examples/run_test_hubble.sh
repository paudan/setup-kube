#!/bin/bash

cilium hubble port-forward&

kubectl create -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/minikube/http-sw-app.yaml

# Might run multiple times
kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing

hubble status

# command terminated with exit code 28
# Run multiple times as well 
kubectl exec xwing -- curl --connect-timeout 2 -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing

# Output statistics
hubble observe --label "class=xwing" --last 10

cat <<EOF | kubectl apply -f -
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "xwing-dns-deny"
spec:
  endpointSelector:
    matchLabels:
      class: xwing
  egressDeny:
  - toEndpoints:
    - matchLabels:
        namespace: kube-system
        k8s-app: kube-dns
EOF

# command terminated with exit code 28
kubectl exec xwing -- curl --connect-timeout 2 -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing

# Policy denied DROPPED (UDP)
hubble observe --label="class=xwing" --to-namespace "kube-system" --last 1

# Ship landed
kubectl exec tiefighter -- curl --connect-timeout 2 -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing

# Apr 10 21:44:02.690: default/tiefighter:56306 (ID:15879) -> kube-system/coredns-76f75df574-2mvr2:53 (ID:17445) to-endpoint FORWARDED (UDP)
hubble observe --label="class=tiefighter" --to-namespace "kube-system" --last 1
