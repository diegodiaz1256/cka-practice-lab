#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace taskns23 --dry-run=client -o yaml | kubectl apply -f -
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server
  namespace: taskns23
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-server
  template:
    metadata:
      labels:
        app: web-server
    spec:
      containers:
        - name: web-server
          image: nginx:1.25
          ports:
            - name: http
              containerPort: 80
EOF
