#!/usr/bin/env bash
# Scenario 32: nodeSelector references a label no node carries
set -euo pipefail
kubectl create namespace scenario32 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: picky-app
  namespace: scenario32
spec:
  replicas: 1
  selector:
    matchLabels:
      app: picky-app
  template:
    metadata:
      labels:
        app: picky-app
    spec:
      nodeSelector:
        tier: platinum
      containers:
        - name: picky-app
          image: nginx:1.25
EOF

echo "Scenario 32 deployed in namespace 'scenario32'. Investigate and fix."
