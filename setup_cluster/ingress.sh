#!/bin/bash

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.5/deploy/static/provider/baremetal/deploy.yaml
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
HTTP_PORT=31760
HTTPS_PORT=31602

gcloud compute firewall-rules create \
kubernetes-cluster-allow-external-ingress \
--allow tcp:$HTTP_PORT,tcp:$HTTPS_PORT \
--network kubernetes-cluster \
--source-ranges 0.0.0.0/0

# Might need this
gcloud compute firewall-rules create kubernetes-cluster-master-nginx-ingress \
--action ALLOW \
--direction INGRESS \
--source-ranges 10.240.0.0/28 \
--rules tcp:443,tcp:8443

WORKER_IP=$(gcloud compute instances describe worker-0 \
--zone $(gcloud config get-value compute/zone) \
--format='get(networkInterfaces[0].accessConfigs[0].natIP)')

curl http://$WORKER_IP:$HTTP_PORT
curl http://$WORKER_IP:$HTTPS_PORT
