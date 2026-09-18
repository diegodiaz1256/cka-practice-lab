#!/usr/bin/env bash
# Scenario 12: ResourceQuota blocking new pod creation
set -euo pipefail
kubectl create namespace scenario12 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tiny-quota
  namespace: scenario12
spec:
  hard:
    pods: "1"
    requests.cpu: "200m"
    requests.memory: 256Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: placeholder
  namespace: scenario12
spec:
  containers:
    - name: app
      image: nginx:1.25
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: newapp
  namespace: scenario12
spec:
  replicas: 2
  selector:
    matchLabels:
      app: newapp
  template:
    metadata:
      labels:
        app: newapp
    spec:
      containers:
        - name: app
          image: nginx:1.25
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
EOF

echo "Scenario 12 deployed in namespace 'scenario12'. Investigate and fix."
