kubectl create sa pipeline -n ns1
kubectl create sa pipeline -n ns2
kubectl create clusterrole deprole --verb=create,delete --resource=deployments
kubectl create clusterrolebinding cluster-role-binding-dep --clusterrole=deprole --serviceaccount=ns1:pipeline --serviceaccount=ns2:pipeline
kubectl create clusterrolebinding cluster-role-binding-view --clusterrole=view --serviceaccount=ns1:pipeline --serviceaccount=ns2:pipeline

# Testing
k auth can-i delete deployments --as system:serviceaccount:ns1:pipeline -n ns1 # YES
k auth can-i create deployments --as system:serviceaccount:ns1:pipeline -n ns1 # YES
k auth can-i update deployments --as system:serviceaccount:ns1:pipeline -n ns1 # NO
k auth can-i update deployments --as system:serviceaccount:ns1:pipeline -n default # NO

# namespace ns2 deployment manager
k auth can-i delete deployments --as system:serviceaccount:ns2:pipeline -n ns2 # YES
k auth can-i create deployments --as system:serviceaccount:ns2:pipeline -n ns2 # YES
k auth can-i update deployments --as system:serviceaccount:ns2:pipeline -n ns2 # NO
k auth can-i update deployments --as system:serviceaccount:ns2:pipeline -n default # NO

# cluster wide view role
k auth can-i list deployments --as system:serviceaccount:ns1:pipeline -n ns1 # YES
k auth can-i list deployments --as system:serviceaccount:ns1:pipeline -A # YES
k auth can-i list pods --as system:serviceaccount:ns1:pipeline -A # YES
k auth can-i list pods --as system:serviceaccount:ns2:pipeline -A # YES
k auth can-i list secrets --as system:serviceaccount:ns2:pipeline -A # NO (default view-role doesn't allow)

# system:serviceaccount matters!
k auth can-i list deployments --as ns1:pipeline -n ns1 # NO
k auth can-i list deployments --as ns1:pipeline -A # NO
k auth can-i list deployments --as serviceaccount:ns1:pipeline -n ns1 # NO
k auth can-i list deployments --as serviceaccount:ns1:pipeline -A # NO
