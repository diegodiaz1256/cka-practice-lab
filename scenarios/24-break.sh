#!/usr/bin/env bash
# Scenario 24: PVC accessMode mismatch - PV is ReadWriteOnce, PVC asks ReadWriteMany
set -euo pipefail
kubectl create namespace scenario24 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: rwo-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: scenario24-sc
  hostPath:
    path: /mnt/scenario24
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-claim
  namespace: scenario24
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: scenario24-sc
  resources:
    requests:
      storage: 1Gi
EOF

echo "Scenario 24 deployed in namespace 'scenario24'. Investigate and fix."
