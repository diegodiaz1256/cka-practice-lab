#!/usr/bin/env bash
# Scenario 1: CrashLoopBackOff from a bad container image + wrong command
set -euo pipefail
kubectl create namespace scenario1 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: scenario1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:1.25
          command: ["nginx-typo", "-g", "daemon off;"]
EOF

echo "Scenario 1 deployed in namespace 'scenario1'. Investigate and fix."
