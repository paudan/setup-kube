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

# get join command
sudo kubeadm token create --print-join-command

sudo kubeadm join 10.240.0.10:6443 --token kpf07i.xcrioq3jomy8ndev \
    --discovery-token-ca-cert-hash sha256:b8519fb28ff30a976166758dbbb3c1c6b6f812a1c4bf26cb927ed3846cf7e6d0
