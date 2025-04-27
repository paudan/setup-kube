#!/bin/bash

# Setup trivy image scanner endpoint
wget https://raw.githubusercontent.com/linuxacademy/content-cks-trivy-k8s-webhook/main/trivy-k8s-webhook.yml
sudo mv trivy-k8s-webhook.yml /etc/kubernetes/manifests
sudo chown root:root /etc/kubernetes/manifests/trivy-k8s-webhook.yml
sudo chmod 600 /etc/kubernetes/manifests/trivy-k8s-webhook.yml
cat "127.0.0.1 acg.trivy.k8s.webhook" | sudo tee /etc/hosts > dev/null

kubectl describe pod -n kube-system trivy-k8s-webhook-controller 

# Test service
curl https://acg.trivy.k8s.webhook:8090/scan -X POST \
    --header "Content-Type: application/json" \
    -d '{"spec":{"containers":[{"image":"nginx:1.19.10"},{"image":"nginx:1.14.1"}]}}' -k

# Setup image admission policy
sudo mkdir /etc/kubernetes/admission-control
sudo wget -O /etc/kubernetes/admission-control/imagepolicywebhook-ca.crt \
https://raw.githubusercontent.com/linuxacademy/content-cks-trivy-k8s-webhook/main/certs/ca.crt
sudo wget -O /etc/kubernetes/admission-control/api-server-client.crt \
https://raw.githubusercontent.com/linuxacademy/content-cks-trivy-k8s-webhook/main/certs/api-server-client.crt
sudo wget -O /etc/kubernetes/admission-control/api-server-client.key \
https://raw.githubusercontent.com/linuxacademy/content-cks-trivy-k8s-webhook/main/certs/api-server-client.key

cat <<EOF | sudo tee /etc/kubernetes/admission-control/admission-control.conf > /dev/null
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/admission-control/imagepolicywebhook_backend.kubeconfig
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: true
EOF

cat <<EOF | sudo tee /etc/kubernetes/admission-control/imagepolicywebhook_backend.kubeconfig > /dev/null
apiVersion: v1
kind: Config
clusters:
- name: trivy-k8s-webhook
  cluster:
    certificate-authority: /etc/kubernetes/admission-control/imagepolicywebhook-ca.crt
    server: https://acg.trivy.k8s.webhook:8090/scan
contexts:
- name: trivy-k8s-webhook
  context:
    cluster: trivy-k8s-webhook
    user: api-server
current-context: trivy-k8s-webhook
preferences: {}
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/admission-control/api-server-client.crt
    client-key: /etc/kubernetes/admission-control/api-server-client.key
EOF

# Update API server settings
# 
# sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
# 
# - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook
# - --admission-control-config-file=/etc/kubernetes/admission-control/admission-control.conf
# 
# volumes:
# - name: admission-control
# hostPath:
#   path: /etc/kubernetes/admission-control
#   type: DirectoryOrCreate
# 
# volumeMounts:
# - name: admission-control
#   mountPath: /etc/kubernetes/admission-control
#   readOnly: true
  

  # Test policy

# This pod should be started successfully 
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: imagepolicy-busybox-pod
spec:
  restartPolicy: Never
  containers:
  - name: busybox
    image: busybox:1.33.1
EOF

# This pod should fail
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: imagepolicy-nginx-pod
spec:
  restartPolicy: Never
  containers:
  - name: nginx
    image: nginx:1.14.2
EOF
