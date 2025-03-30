#!/bin/bash

openssl genrsa -out 60099.key 2048
openssl req -new -subj "/CN=60099@internal.users" -key 60099.key -out 60099.csr

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: user-csr
spec:
  groups:
  - system:authenticated
  request: $(cat 60099.csr | base64 -w 0)
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF
kubectl get csr user-csr
kubectl certificate approve user-csr
kubectl get csr user-csr -o jsonpath='{.status.certificate}' | base64 --decode > 60099.crt

# Create user kubeconfig
kubectl config set-credentials 60099@internal.users --client-key=60099.key --client-certificate=60099.crt
kubectl config set-context 60099@internal.users --cluster=kubernetes --user=60099@internal.users
kubectl config get-contexts
kubectl config use-context 60099@internal.users
