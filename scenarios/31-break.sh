#!/usr/bin/env bash
# Scenario 31: both workers cordoned, nothing new can schedule
set -euo pipefail
kubectl create namespace scenario31 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl cordon cka-practice-worker >/dev/null
kubectl cordon cka-practice-worker2 >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: waiting-app
  namespace: scenario31
spec:
  replicas: 2
  selector:
    matchLabels:
      app: waiting-app
  template:
    metadata:
      labels:
        app: waiting-app
    spec:
      containers:
        - name: waiting-app
          image: nginx:1.25
EOF

echo "Scenario 31 deployed in namespace 'scenario31'. Investigate and fix."
