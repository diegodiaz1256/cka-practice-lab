#!/usr/bin/env bash
# Scenario 19: wrong toleration operator - pod stays Pending despite toleration present
set -euo pipefail
kubectl create namespace scenario19 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl taint node cka-practice-worker special=true:NoSchedule --overwrite

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: toleration-pod
  namespace: scenario19
spec:
  nodeSelector:
    kubernetes.io/hostname: cka-practice-worker
  tolerations:
    - key: "special"
      operator: "Equal"
      value: "false"
      effect: "NoSchedule"
  containers:
    - name: app
      image: nginx:1.25
EOF

echo "Scenario 19 deployed in namespace 'scenario19'. Investigate and fix."
