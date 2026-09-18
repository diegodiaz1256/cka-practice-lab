#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace taskns26 --dry-run=client -o yaml | kubectl apply -f -
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: taskns26
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: nginx:1.25
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: taskns26
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: registry.k8s.io/echoserver:1.10
          ports:
            - containerPort: 8080
EOF
