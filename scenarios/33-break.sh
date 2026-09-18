#!/usr/bin/env bash
# Scenario 33: StatefulSet stuck - its volumeClaimTemplate names a StorageClass that doesn't exist
set -euo pipefail
kubectl create namespace scenario33 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: statefuldb
  namespace: scenario33
spec:
  clusterIP: None
  selector:
    app: statefuldb
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: statefuldb
  namespace: scenario33
spec:
  serviceName: statefuldb
  replicas: 1
  selector:
    matchLabels:
      app: statefuldb
  template:
    metadata:
      labels:
        app: statefuldb
    spec:
      containers:
        - name: statefuldb
          image: nginx:1.25
          volumeMounts:
            - name: data
              mountPath: /data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: nvme-tier
        resources:
          requests:
            storage: 200Mi
EOF

echo "Scenario 33 deployed in namespace 'scenario33'. Investigate and fix."
