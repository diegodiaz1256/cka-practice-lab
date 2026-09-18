#!/usr/bin/env bash
# Scenario 16: ConfigMap reference missing - pod stuck CreateContainerConfigError
set -euo pipefail
kubectl create namespace scenario16 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cfgapp
  namespace: scenario16
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cfgapp
  template:
    metadata:
      labels:
        app: cfgapp
    spec:
      containers:
        - name: cfgapp
          image: nginx:1.25
          envFrom:
            - configMapRef:
                name: app-settings
EOF

echo "Scenario 16 deployed in namespace 'scenario16'. Investigate and fix."
