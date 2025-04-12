#!/bin/bash

sudo swapoff -a
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

#Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

#Apply sysctl params without reboot
sudo sysctl --system  

gcloud config set compute/zone us-west1-c
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute instances describe controller \
--zone $(gcloud config get-value compute/zone) \
--format='get(networkInterfaces[0].accessConfigs[0].natIP)')
sudo kubeadm init \
--pod-network-cidr=192.168.0.0/16 \
--ignore-preflight-errors=NumCPU \
--apiserver-cert-extra-sans=$KUBERNETES_PUBLIC_ADDRESS

# Remove the taint
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# Set admin access to cluster
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# install helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# Install Calico addon
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
# Version matters!
curl -L https://github.com/projectcalico/calico/releases/download/v3.25.0/calicoctl-linux-amd64 -o kubectl-calico
chmod +x kubectl-calico
sudo cp kubectl-calico /usr/bin
kubectl calico get nodes

# Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml
kubectl edit -n kube-system deploy metrics-server
# Add to spec.containers.args
# - --kubelet-insecure-tls
# - --secure-port=4443
# Set ports.containerPort:
# - containerPort: 4443
# Add to spec:
# hostNetwork: true
kubectl top pods -n kube-system  # Test

# Install Gateway API
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml
