#!/usr/bin/env bash
# Scenario 25: PVC requests more storage than the available PV offers
set -euo pipefail
kubectl create namespace scenario25 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: small-pv
spec:
  capacity:
    storage: 500Mi
  accessModes:
    - ReadWriteOnce
  storageClassName: scenario25-sc
  hostPath:
    path: /mnt/scenario25
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: big-claim
  namespace: scenario25
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: scenario25-sc
  resources:
    requests:
      storage: 10Gi
EOF

echo "Scenario 25 deployed in namespace 'scenario25'. Investigate and fix."
