#!/usr/bin/env bash
# Scenario 9: PVC stuck Pending - references a non-existent StorageClass
set -euo pipefail
kubectl create namespace scenario9 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-claim
  namespace: scenario9
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db
  namespace: scenario9
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
        - name: db
          image: nginx:1.25
          volumeMounts:
            - name: data
              mountPath: /data
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: data-claim
EOF

echo "Scenario 9 deployed in namespace 'scenario9'. Investigate and fix."
