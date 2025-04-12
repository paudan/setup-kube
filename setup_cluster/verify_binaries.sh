#!/bin/bash

KUBE_VERSION=$(kubectl version --client -o json | jq --raw-output .clientVersion.gitVersion)
curl -LO "https://dl.k8s.io/$KUBE_VERSION/bin/linux/amd64/kubectl.sha256"
echo "$(<kubectl.sha256) /usr/bin/kubectl" | sha256sum --check
