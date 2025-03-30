#!/bin/bash

# Check API version
kubectl api-versions | grep certif
# Create user john CSR
openssl genrsa -out john.key 2048
# Important: subj matters!
openssl req -new -subj "/C=developer" -key john.key -out john.csr
# Sign user certificate and approve it
USER_NAME="john-developer"
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: user-csr
spec:
  request: $(cat john.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF
kubectl get certificatesigningrequests.certificates.k8s.io user-csr
kubectl certificate approve user-csr
kubectl get csr
kubectl get csr user-csr -o jsonpath='{.status.certificate}' | base64 --decode > user.crt

# Create user kubeconfig as userconfig
CLUSTER_ENDPOINT=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
echo -n $CLUSTER_CA | base64 -d > cluster.crt
CLUSTER_NAME=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].name}')
kubectl --kubeconfig=userconfig config set-cluster $CLUSTER_NAME \
--server=$CLUSTER_ENDPOINT \
--certificate-authority=cluster.crt --embed-certs
kubectl --kubeconfig=userconfig config set-credentials $USER_NAME \
--client-certificate=user.crt --embed-certs
kubectl --kubeconfig=userconfig config set-context default \
--cluster=$CLUSTER_NAME \
--user=$USER_NAME \
--namespace=default

# Create cluster role to read cluster info
kubectl create clusterrole nodes-read --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding user-nodes-read --clusterrole=nodes-read --user=$USER_NAME

# User must add his private key to userconfig given to him
kubectl --kubeconfig=userconfig config set-credentials $USER_NAME \
--client-key=user.key --embed-certs

# Check if role works for the user
kubectl --kubeconfig=userconfig config use-context default
kubectl --kubeconfig=userconfig get nodes  # Should work
kubectl --kubeconfig=userconfig get pods   # Should not work

# Create developer role
kubectl create role developer --resource=pods --verb=create,list,get,update,delete
kubectl create rolebinding developer-role-binding --role=developer --user=$USER_NAME
# Test role
kubectl auth can-i update pods   # yes
kubectl auth can-i update pods --as=$USER_NAME  # yes
kubectl auth can-i patch pods --as=$USER_NAME  # no
kubectl auth can-i update deployments --as=$USER_NAME  # no
# Test with user authentication
kubectl auth can-i update pods --kubeconfig=userconfig  # yes
kubectl auth can-i patch pods --kubeconfig=userconfig  # no
kubectl auth can-i update deployments --kubeconfig=userconfig  # no
