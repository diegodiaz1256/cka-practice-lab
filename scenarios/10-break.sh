#!/usr/bin/env bash
# Scenario 10: NetworkPolicy default-deny blocks all ingress to a pod
set -euo pipefail
kubectl create namespace scenario10 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: scenario10
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: registry.k8s.io/echoserver:1.10
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
  namespace: scenario10
spec:
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: scenario10
spec:
  podSelector: {}
  policyTypes:
    - Ingress
EOF

echo "Scenario 10 deployed in namespace 'scenario10'. Investigate and fix."
