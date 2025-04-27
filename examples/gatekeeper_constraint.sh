#!/bin/bash

kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.19.0/deploy/gatekeeper.yaml

cat <<EOF | kubectl apply -f -
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          properties:
            labels:
              type: array
              items: string
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8srequiredlabels
      
      violation[{"msg": msg, "details": {"missing_labels": missing}}] {
        provided := {label | input.review.object.metadata.labels[label]}
        required := {label | label := input.parameters.labels[_]}
        missing := required - provided
        count(missing) > 0
        msg := sprintf("you must provide labels: %v", [missing])
      }
EOF

cat <<EOF | kubectl apply -f -
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: dep-must-have-contact
spec:
  match:
    kinds:
    - apiGroups: ["apps"]
      kinds: ["Deployment"]
  parameters:
    labels: ["contact"]
EOF

# Test constraints
# Fails as no contact label is given
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opa-test-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opa-test
  template:
    metadata:
      labels:
        app: opa-test
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
EOF

# Works now
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opa-test-deployment
  labels:
    contact: PeterPeterson 
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opa-test
  template:
    metadata:
      labels:
        app: opa-test
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
EOF

# Delete constraint when not needed 
kubectl delete K8sRequiredLabels dep-must-have-contact
