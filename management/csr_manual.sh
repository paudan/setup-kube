#!/bin/bash

openssl genrsa -out 60099.key 2048
openssl req -new -subj "/CN=60099@internal.users" -key 60099.key -out 60099.csr
# find /etc/kubernetes/pki | grep ca
openssl x509 -req -in 60099.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out 60099.crt -days 500

# Create user kubeconfig
kubectl config set-credentials 60099@internal.users --client-key=60099.key --client-certificate=60099.crt
kubectl config set-context 60099@internal.users --cluster=kubernetes --user=60099@internal.users
kubectl config get-contexts
kubectl config use-context 60099@internal.users
