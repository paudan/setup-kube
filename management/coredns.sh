#Run some DNS queries against the kube-dns service cluster ip to ensure everything works...
SERVICEIP=$(kubectl get service --namespace kube-system kube-dns -o jsonpath='{ .spec.clusterIP }')
nslookup www.pluralsight.com $SERVICEIP
nslookup www.centinosystems.com $SERVICEIP

# Get configuration
kubectl -n kube-system get configmap coredns -o yaml > coredns_backup.yaml
# Add custom-domain to config
# Restart deployment after modifications
kubectl -n kube-system rollout restart deploy coredns

# Test config
kubectl run bb --image=busybox --restart=Never --rm -it -- nslookup kubernetes.default.svc.cluster.local
kubectl run bb --image=busybox --restart=Never --rm -it -- nslookup kubernetes.default.svc.custom-domain
