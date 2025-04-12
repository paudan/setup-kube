#!/bin/bash

# Create network 
gcloud compute networks create kubernetes-cluster --subnet-mode custom
gcloud compute networks subnets create kubernetes \
--network kubernetes-cluster \
--range 10.240.0.0/24
gcloud compute firewall-rules create kubernetes-cluster-allow-internal \
--allow tcp,udp,icmp,ipip \
--network kubernetes-cluster \
--source-ranges 10.240.0.0/24,10.244.0.0/16
gcloud compute firewall-rules create kubernetes-cluster-allow-external \
--allow tcp:22,tcp:6443,icmp \
--network kubernetes-cluster \
--source-ranges 0.0.0.0/0
gcloud compute firewall-rules create kubernetes-cluster-allow-hubble \
--allow tcp:4244-4245 \
--network kubernetes-cluster \
--source-ranges 0.0.0.0/0

# Reserve a public IP address for the controller
gcloud compute addresses create kubernetes-controller \
--region $(gcloud config get-value compute/region)
PUBLIC_IP=$(gcloud compute addresses describe kubernetes-controller \
--region $(gcloud config get-value compute/region) \
--format 'value(address)')

# Create controller and workers VMs
gcloud compute instances create controller \
--boot-disk-size 200GB \
--can-ip-forward \
--image-family ubuntu-2004-lts \
--image-project ubuntu-os-cloud \
--machine-type e2-medium \
--private-network-ip 10.240.0.10 \
--scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
--subnet kubernetes \
--address $PUBLIC_IP
for i in 0 1; do \
gcloud compute instances create worker-${i} \
--boot-disk-size 200GB \
--can-ip-forward \
--image-family ubuntu-2004-lts \
--image-project ubuntu-os-cloud \
--machine-type e2-small \
--private-network-ip 10.240.0.2${i} \
--scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
--subnet kubernetes; \
done
