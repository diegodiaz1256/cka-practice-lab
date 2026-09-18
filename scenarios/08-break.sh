#!/usr/bin/env bash
# Scenario 8: Pod Pending due to taint with no matching toleration
set -euo pipefail
kubectl create namespace scenario8 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl taint node cka-practice-worker2 dedicated=gpu:NoSchedule --overwrite

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: needs-gpu-node
  namespace: scenario8
spec:
  nodeSelector:
    kubernetes.io/hostname: cka-practice-worker2
  containers:
    - name: app
      image: nginx:1.25
EOF

echo "Scenario 8 deployed in namespace 'scenario8'. Investigate and fix."
