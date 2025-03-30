# Get etcd information
POD_NAME=$(kubectl get pods -n kube-system | grep etcd | cut -d " " -f 1)
SERVER_KEY=$(kubectl describe $POD_NAME -n kube-system | grep "\-\-key-file" | cut -d "=" -f 2)
SERVER_CERT=$(kubectl describe $POD_NAME -n kube-system | grep "\-\-cert-file" | cut -d "=" -f 2)
EXPIRATION_DATE=$(sudo openssl x509 -enddate -noout -in $SERVER_CERT)
AUTH_ENABLED=$(kubectl describe $POD_NAME -n kube-system | grep "\-\-client-cert-auth" | cut -d "=" -f 2)
echo "$SERVER_KEY,$EXPIRATION_DATE,$AUTH_ENABLED" > etcd-info.txt

# Backup etcd
sudo apt install etcd-client
sudo ETCDCTL_API=3 etcdctl \
    --endpoints=localhost:2379 \
    --cacert /etc/kubernetes/pki/etcd/ca.crt \
    --cert /etc/kubernetes/pki/etcd/server.crt \
    --key /etc/kubernetes/pki/etcd/server.key \
    snapshot save snapshot.db >& backup_log.log

# Snapshot status
ETCDCTL_API=3 etcdctl --write-out=table snapshot status snapshot.db

# Restore etcd
sudo ETCDCTL_API=3 etcdctl \
snapshot restore snapshot.db \
--data-dir /var/lib/etcd-from-backup \
--initial-cluster master-1=https://192.168.5.11:2380,master-2=https://192.168.5.12:2380 \
--initial-cluster-token etcd-cluster-1 \
--initial-advertise-peer-urls https://${INTERNAL_IP}:2380
# Simple version
sudo ETCDCTL_API=3 etcdctl \
snapshot restore snapshot.db \
--data-dir /root/default.etcd \
--initial-cluster-token controlplane  >& restore_log.log
