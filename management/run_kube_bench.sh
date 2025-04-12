#!/bin/bash

wget -O kube-bench-control-plane.yaml https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job-master.yaml
wget -O kube-bench-node.yaml https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job-node.yaml

kubectl create -f kube-bench-control-plane.yaml
kubectl create -f kube-bench-node.yaml

MASTER_POD=$(kubectl get pods -l job-name=kube-bench-master -o name)
kubectl logs $MASTER_POD >  kube-bench-results-control-plane.log
NODE_POD=$(kubectl get pods -l job-name=kube-bench-node -o name)
kubectl logs $NODE_POD >  kube-bench-results-node.log
