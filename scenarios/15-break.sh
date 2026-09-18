#!/usr/bin/env bash
# Scenario 15: Service targetPort mismatch (not selector) - endpoints exist but connections refused
set -euo pipefail
kubectl create namespace scenario15 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portapp
  namespace: scenario15
spec:
  replicas: 1
  selector:
    matchLabels:
      app: portapp
  template:
    metadata:
      labels:
        app: portapp
    spec:
      containers:
        - name: portapp
          image: nginx:1.25
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: portapp-svc
  namespace: scenario15
spec:
  selector:
    app: portapp
  ports:
    - port: 80
      targetPort: 8080
EOF

echo "Scenario 15 deployed in namespace 'scenario15'. Investigate and fix."
