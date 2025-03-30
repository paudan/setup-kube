# Kubelet client certificate
# Issuer info
sudo openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet-client-current.pem | grep -i issuer
# Extended Key Usage
sudo openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet-client-current.pem | grep -i "Extended Key Usage" -A1

# Kubelet server certificate
# Issuer info
sudo openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet.crt | grep -i issuer
# Extended Key Usage
sudo openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet.crt | grep -i "Extended Key Usage" -A1
