#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace taskns25 --dry-run=client -o yaml | kubectl apply -f -
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: taskns25
data:
  greeting: "hello from configmap"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bareapp
  namespace: taskns25
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bareapp
  template:
    metadata:
      labels:
        app: bareapp
    spec:
      containers:
        - name: bareapp
          image: nginx:1.25
EOF
