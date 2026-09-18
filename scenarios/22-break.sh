#!/usr/bin/env bash
# Scenario 22: readinessProbe wrong port - pod Running but never Ready, Service has no endpoints
set -euo pipefail
kubectl create namespace scenario22 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: readyapp
  namespace: scenario22
spec:
  replicas: 1
  selector:
    matchLabels:
      app: readyapp
  template:
    metadata:
      labels:
        app: readyapp
    spec:
      containers:
        - name: readyapp
          image: nginx:1.25
          ports:
            - containerPort: 80
          readinessProbe:
            tcpSocket:
              port: 81
            periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: readyapp-svc
  namespace: scenario22
spec:
  selector:
    app: readyapp
  ports:
    - port: 80
      targetPort: 80
EOF

echo "Scenario 22 deployed in namespace 'scenario22'. Investigate and fix."
