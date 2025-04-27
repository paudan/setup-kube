#!/bin/bash

# Create secret and test it
SECRET=secretpassword
kubectl create secret generic new-secret -n default --from-literal=user=$SECRET
sudo ETCDCTL_API=3 etcdctl \
   --cacert=/etc/kubernetes/pki/etcd/ca.crt   \
   --cert=/etc/kubernetes/pki/etcd/server.crt \
   --key=/etc/kubernetes/pki/etcd/server.key  \
   get /registry/secrets/default/new-secret 
# This identifies that file is stored unencrypted   
sudo bash -c "cd /var/lib/etcd && grep -R $SECRET"

# Create encryption config
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

sudo mkdir -p /etc/kubernetes/encryption
cat <<EOF | sudo tee /etc/kubernetes/encryption/encryption-at-rest.yaml > /dev/null
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

# Update API server settings
# 
# sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
# 
# --encryption-provider-config=/etc/kubernetes/encryption/encryption-at-rest.yaml
# 
# volumes:
# - name: encryption
# hostPath:
#   path: /etc/kubernetes/encryption
#   type: DirectoryOrCreate
# 
# volumeMounts:
# - name: encryption
#   mountPath: /etc/kubernetes/encryption
#   readOnly: true

SECRET=dbpassword
kubectl create secret generic db-secret -n default --from-literal=dbadmin=$SECRET
# The secret is stored encrypted: k8s:enc:aescbc:v1:key1 
sudo ETCDCTL_API=3 etcdctl \
   --cacert=/etc/kubernetes/pki/etcd/ca.crt   \
   --cert=/etc/kubernetes/pki/etcd/server.crt \
   --key=/etc/kubernetes/pki/etcd/server.key  \
   get /registry/secrets/default/db-secret
# Now secret is not found by probing directly   
sudo bash -c "cd /var/lib/etcd && grep -R $SECRET"
