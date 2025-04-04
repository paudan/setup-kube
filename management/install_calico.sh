#!/bin/bash

# https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/custom-resources.yaml -O
# kubectl create -f custom-resources.yaml

kubectl get pods -n tigera-operator
kubectl get pods -n calico-system
# or
# kubectl get pods -A | grep calico

kubectl taint nodes --all node-role.kubernetes.io/control-plane

# get cluster CIDR with:
kubectl cluster-info dump | grep -m 1 service-cluster-ip-range
# or:
# kubeadm config print init-defaults | grep "serviceSubnet"

cat <<EOF |  kubectl apply -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  cni:
    type: Calico
  calicoNetwork:
    bgp: Disabled
    ipPools:
      - cidr: 10.96.0.0/12
        encapsulation: VXLAN
        natOutgoing: Enabled
        nodeSelector: all()
---
EOF

kubectl get installations.operator.tigera.io default -o yaml

