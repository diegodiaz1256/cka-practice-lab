#!/usr/bin/env bash
# Scenario 18: Secret reference missing key - pod CreateContainerConfigError
set -euo pipefail
kubectl create namespace scenario18 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
  namespace: scenario18
type: Opaque
stringData:
  username: admin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secretapp
  namespace: scenario18
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secretapp
  template:
    metadata:
      labels:
        app: secretapp
    spec:
      containers:
        - name: secretapp
          image: nginx:1.25
          env:
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: password
EOF

echo "Scenario 18 deployed in namespace 'scenario18'. Investigate and fix."
