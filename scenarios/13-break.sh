#!/usr/bin/env bash
# Scenario 13: bad livenessProbe kills a healthy app in an endless restart loop
set -euo pipefail
kubectl create namespace scenario13 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web2
  namespace: scenario13
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web2
  template:
    metadata:
      labels:
        app: web2
    spec:
      containers:
        - name: web2
          image: nginx:1.25
          livenessProbe:
            httpGet:
              path: /healthz
              port: 9999
            initialDelaySeconds: 2
            periodSeconds: 3
EOF

echo "Scenario 13 deployed in namespace 'scenario13'. Investigate and fix."
