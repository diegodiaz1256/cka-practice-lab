#!/usr/bin/env bash
# Scenario 7: ImagePullBackOff - typo'd image name
set -euo pipefail
kubectl create namespace scenario7 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cache
  namespace: scenario7
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
    spec:
      containers:
        - name: cache
          image: redis:7-alpien
EOF

echo "Scenario 7 deployed in namespace 'scenario7'. Investigate and fix."
