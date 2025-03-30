
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
spec:
  defaultBackend:
    service:
      name: webapp
      port:
        number: 80
EOF

# Deploy second application
kubectl create deployment echo --image=kennship/http-echo
kubectl expose deployment echo --port 3000
kubectl delete ingress webapp-ingress

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -out echo-ingress-tls.crt \
  -keyout echo-ingress-tls.key \
  -subj "/CN=echo.com/O=echo-ingress-tls"
kubectl create secret tls echo-ingress-tls \
--key echo-ingress-tls.key \
--cert echo-ingress-tls.crt

kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: plex-ingress
spec:
  tls:
  - hosts:
    - echo.com
    secretName: echo-ingress-tls
  rules:
  - host: webapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp
            port:
              number: 80
  - host: echo.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: echo
            port:
              number: 3000
EOF

curl -k -v --resolve echo.com:$HTTPS_PORT:$WORKER_IP https://echo.com:$HTTPS_PORT/
curl -k -v --resolve webapp.com:$HTTPS_PORT:$WORKER_IP https://webapp.com:$HTTPS_PORT
