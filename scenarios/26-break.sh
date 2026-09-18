#!/usr/bin/env bash
# Scenario 26: subPath typo means the app reads an empty dir instead of its config
set -euo pipefail
kubectl create namespace scenario26 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: site-config
  namespace: scenario26
data:
  index.html: "<h1>cka practice</h1>"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: siteapp
  namespace: scenario26
spec:
  replicas: 1
  selector:
    matchLabels:
      app: siteapp
  template:
    metadata:
      labels:
        app: siteapp
    spec:
      containers:
        - name: siteapp
          image: nginx:1.25
          volumeMounts:
            - name: site
              mountPath: /usr/share/nginx/html/index.html
              subPath: index.htm
      volumes:
        - name: site
          configMap:
            name: site-config
EOF

echo "Scenario 26 deployed in namespace 'scenario26'. Investigate and fix."
