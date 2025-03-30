 #!/bin/bash
 
 gcloud compute scp controller:~/.kube/config kubeconfig
 KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute instances describe controller \
--zone $(gcloud config get-value compute/zone) \
--format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# Update downloaded config
sed -i "s/10.240.0.10/$KUBERNETES_PUBLIC_ADDRESS/" kubeconfig
sed -i 's/kubernetes/cka/' kubeconfig

# Move if no other configs are available
mkdir $HOME/.kube
mv -i kubeconfig $HOME/.kube/config
# Or merge with existing
KUBECONFIG=$HOME/.kube/config:kubeconfig kubectl config view --merge --flatten > config && mv config $HOME/.kube/config

# Get worker IP
WORKER_IP=$(gcloud compute instances describe worker-0 \
--zone $(gcloud config get-value compute/zone) \
--format='get(networkInterfaces[0].accessConfigs[0].natIP)')
