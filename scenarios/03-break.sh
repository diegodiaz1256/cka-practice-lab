#!/usr/bin/env bash
# Scenario 3: Pod stuck Pending - resource request exceeds any node's allocatable
set -euo pipefail
kubectl create namespace scenario3 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: big-pod
  namespace: scenario3
spec:
  containers:
    - name: hog
      image: nginx:1.25
      resources:
        requests:
          cpu: "100"
          memory: "500Gi"
EOF

echo "Scenario 3 deployed in namespace 'scenario3'. Investigate and fix."
