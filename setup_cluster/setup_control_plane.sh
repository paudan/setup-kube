#!/bin/bash

# Required for kubernetes<1.36
# sudo swapoff -a
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
# On local deployment could be similar to:
# KUBERNETES_PUBLIC_ADDRESS=$(hostname -I | cut -d " " -f 1)

# Traditional way
# sudo kubeadm init \
# --pod-network-cidr=192.168.0.0/16 \
# --ignore-preflight-errors=NumCPU \
# --apiserver-cert-extra-sans=$KUBERNETES_PUBLIC_ADDRESS

# For more recent versions, which allow to use swap 
cat <<EOF | sudo tee /etc/kubernetes/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
nodeRegistration:
  ignorePreflightErrors:
    - Swap
    - NumCPU
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
apiServer:
  certSANs: 
  - $KUBERNETES_PUBLIC_ADDRESS
kubernetesVersion: v1.37.1
networking:
  podSubnet: "192.168.0.0/16"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
failSwapOn: false
memorySwap:
  swapBehavior: LimitedSwap
EOF
sudo kubeadm init --config /etc/kubernetes/kubeadm-config.yaml

# Remove the taint
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# Set admin access to cluster
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico addon
# Traditional way
# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.33.0/manifests/v3_projectcalico_org.yaml
# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.33.0/manifests/tigera-operator.yaml
# curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.33.0/manifests/custom-resources-bpf.yaml | kubectl create -f -
# With Helm
helm repo add projectcalico https://docs.tigera.io/calico/charts
kubectl create namespace tigera-operator
helm template calico-crds projectcalico/projectcalico.org.v3 --version v3.33.0 --api-versions admissionregistration.k8s.io/v1/MutatingAdmissionPolicy | kubectl apply --server-side -f -
helm install calico projectcalico/tigera-operator --version v3.33.0 --namespace tigera-operator
watch kubectl get pods -n calico-system

# Version matters!
curl -L https://github.com/projectcalico/calico/releases/download/v3.33.0/calicoctl-linux-amd64 -o calicoctl
chmod +x calicoctl
sudo cp calicoctl /usr/bin
sudo ln -s /usr/bin/calicoctl /usr/bin/kubectl-calico  # To use directly inside kubectl
kubectl calico get nodes

# Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.0/components.yaml
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
