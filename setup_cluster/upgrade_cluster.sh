# run for both control plane and every node
kubectl cordon node01
kubectl drain node01 --ignore-daemonsets  # Clear node and cordon it

ssh node01

# see possible versions
kubeadm upgrade plan

# show available versions
apt-cache show kubeadm

# can be different
apt-mark unhold kubeadm kubelet kubectl 
apt-get install kubeadm=1.32.2-1.1 kubectl=1.32.2-1.1 kubelet=1.32.2-1.1
apt-mark hold kubeadm kubelet kubectl

# could be a different version, it can also take a bit to finish!
kubeadm upgrade apply v1.32.2
# If ETCD is not required to be upgraded:
kubeadm upgrade apply v1.32.2 --etcd-upgrade=false

systemctl daemon-reload
systemctl restart kubelet

exit
kubectl uncordon node01
