#!/bin/bash

# Create test pods and test their connection
kubectl run test1 --image=busybox:1.28 --restart=Never -- sleep 3600
kubectl run test2 --image=busybox:1.28 --restart=Never -- sleep 3600
# ping command should work
kubectl exec test1 -- ping -c 4 test2
# by full DNS name
kubectl exec test1 -- ping -c 4 192-168-43-2.default.pod.cluster.local

# Restrict pod connectivity
cat <<EOF |  kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# network CIDR is 192.168.0.0/16
# ping command should not work, as enforced by the network policy
kubectl exec test1 -- ping -c 4 192.168.196.130
