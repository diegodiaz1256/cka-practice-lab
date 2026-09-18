#!/usr/bin/env bash
# Scenario 20: readOnlyRootFilesystem blocks nginx from writing pid/cache - CrashLoopBackOff
set -euo pipefail
kubectl create namespace scenario20 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: roapp
  namespace: scenario20
spec:
  replicas: 1
  selector:
    matchLabels:
      app: roapp
  template:
    metadata:
      labels:
        app: roapp
    spec:
      containers:
        - name: roapp
          image: nginx:1.25
          securityContext:
            readOnlyRootFilesystem: true
EOF

echo "Scenario 20 deployed in namespace 'scenario20'. Investigate and fix."
