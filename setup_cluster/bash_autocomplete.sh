 sudo apt install -y bash-completion
 echo "source <(kubectl completion bash)" >> ~/.bashrc
 echo "source <(kubeadm completion bash)" >> ~/.bashrc
 source ~/.bashrc
