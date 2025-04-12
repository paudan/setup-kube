kubectl apply -f gvisor_sandbox_test.yaml
kubectl exec non-sandbox-pod -- dmesg
kubectl exec sandbox-pod -- dmesg
