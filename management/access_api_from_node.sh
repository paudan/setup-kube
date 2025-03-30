kubectl exec api-contact -n project-ns -- sh #
# Run inside
# Will not work, will result in "secrets is forbidden"
curl -k https://kubernetes.default/api/v1/secrets
# Get token to use pod's SecretAccount defined in manifest
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
# Run with token, then it will return secrets
curl -k https://kubernetes.default/api/v1/secrets -H "Authorization: Bearer $TOKEN" > result.json
# If CA certification is used
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
curl --cacert ${CACERT} https://kubernetes.default/api/v1/secrets -H "Authorization: Bearer $TOKEN" > result.json
exit

# To retrieve it, run again from the host pod 
k -n project-ns exec api-contact -it -- cat result.json > /opt/result.json

# Check if service account can actually lists secrets
# project-ns is the namespace, secret-reader is the sa
k auth can-i get secret --as system:serviceaccount:project-ns:secret-reader
