#!/usr/bin/env bash
# Scenario 2: Service with mismatched selector - Endpoints empty, no traffic reaches pods
set -euo pipefail
kubectl create namespace scenario2 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: scenario2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
        - name: api
          image: registry.k8s.io/echoserver:1.10
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: api-svc
  namespace: scenario2
spec:
  selector:
    app: api-backend
  ports:
    - port: 80
      targetPort: 8080
EOF

echo "Scenario 2 deployed in namespace 'scenario2'. Investigate and fix."
