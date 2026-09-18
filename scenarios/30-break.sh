#!/usr/bin/env bash
# Scenario 30: LimitRange default request is larger than the namespace quota allows
set -euo pipefail
kubectl create namespace scenario30 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: heavy-defaults
  namespace: scenario30
spec:
  limits:
    - type: Container
      default:
        cpu: "2"
        memory: 2Gi
      defaultRequest:
        cpu: "2"
        memory: 2Gi
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: modest-quota
  namespace: scenario30
spec:
  hard:
    requests.cpu: "500m"
    requests.memory: 512Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: limitedapp
  namespace: scenario30
spec:
  replicas: 1
  selector:
    matchLabels:
      app: limitedapp
  template:
    metadata:
      labels:
        app: limitedapp
    spec:
      containers:
        - name: limitedapp
          image: nginx:1.25
EOF

echo "Scenario 30 deployed in namespace 'scenario30'. Investigate and fix."
