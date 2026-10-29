#!/usr/bin/env bash
# Node setup (uses sudo): registry.kube.org resolves to this node and Docker and containerd trust the registry CA created
# by tls.yaml. Idempotent; containerd restarts only when its registry config path is first set.
set -euo pipefail
HOST=registry.kube.org

grep -qw "$HOST" /etc/hosts || echo "127.0.0.1 $HOST" | sudo tee -a /etc/hosts >/dev/null

CA=$(kubectl -n docker-registry get secret registry-ca -o jsonpath='{.data.ca\.crt}' | base64 -d)
# Docker reads the CA per registry, no restart needed: the system daemon from /etc/docker, the rootless one from ~/.config/docker
sudo mkdir -p "/etc/docker/certs.d/$HOST"
echo "$CA" | sudo tee "/etc/docker/certs.d/$HOST/ca.crt" >/dev/null
mkdir -p "$HOME/.config/docker/certs.d/$HOST"
echo "$CA" > "$HOME/.config/docker/certs.d/$HOST/ca.crt"

# containerd (kubelet pulls through it): per-registry hosts.toml with the CA next to it
sudo mkdir -p "/etc/containerd/certs.d/$HOST"
echo "$CA" | sudo tee "/etc/containerd/certs.d/$HOST/ca.crt" >/dev/null
sudo tee "/etc/containerd/certs.d/$HOST/hosts.toml" >/dev/null <<TOML
server = "https://$HOST"

[host."https://$HOST"]
  capabilities = ["pull", "resolve"]
  ca = "ca.crt"
TOML
if ! containerd config dump | grep -q "config_path = '/etc/containerd/certs.d"; then
  [ ! -e /etc/containerd/config.toml ] || { echo "set config_path = '/etc/containerd/certs.d' under [plugins.'io.containerd.cri.v1.images'.registry] in /etc/containerd/config.toml" >&2; exit 1; }
  sudo tee /etc/containerd/config.toml >/dev/null <<TOML
version = 4

[plugins.'io.containerd.cri.v1.images'.registry]
  config_path = '/etc/containerd/certs.d'
TOML
  sudo systemctl restart containerd
fi
