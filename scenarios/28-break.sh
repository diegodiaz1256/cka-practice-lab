#!/usr/bin/env bash
# Scenario 28: headless Service (clusterIP: None) used where a routable ClusterIP is needed
set -euo pipefail
kubectl create namespace scenario28 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: headless-app
  namespace: scenario28
spec:
  replicas: 1
  selector:
    matchLabels:
      app: headless-app
  template:
    metadata:
      labels:
        app: headless-app
    spec:
      containers:
        - name: headless-app
          image: nginx:1.25
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: headless-svc
  namespace: scenario28
spec:
  clusterIP: None
  selector:
    app: headless-app
  ports:
    - port: 80
      targetPort: 80
EOF

echo "Scenario 28 deployed in namespace 'scenario28'. The Service needs a routable ClusterIP. Investigate and fix."
