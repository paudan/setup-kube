#!/bin/bash

curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | \
sudo gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main" | \
sudo tee -a /etc/apt/sources.list.d/falcosecurity.list

sudo apt install -y dkms make linux-headers-$(uname -r) clang llvm dialog
sudo apt-get install -y falco

# Check falco rules execution
# cat /var/log/syslog | grep falco
