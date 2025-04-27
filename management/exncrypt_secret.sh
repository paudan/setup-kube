#!/bin/bash 

# Recreate secret to enable encryption
kubectl get secrets s1 -n one -o yaml | kubectl replace -f -
# OR: replace all secrets in the namespace:
kubectl -n one get secrets -o json | kubectl replace -f -

# Verify if the secret s1 has been encrypted
# Result would be encryoted and prefixed with: k8s:enc:aescbc:v1:key1:
ETCDCTL_API=3 etcdctl --cert /etc/kubernetes/pki/apiserver-etcd-client.crt \
--key /etc/kubernetes/pki/apiserver-etcd-client.key \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
get /registry/secrets/one/s1
