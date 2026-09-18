#!/usr/bin/env bash
# Scenario 17: Job never completes - command always fails, backoffLimit exhausted
set -euo pipefail
kubectl create namespace scenario17 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: batchjob
  namespace: scenario17
spec:
  backoffLimit: 2
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: worker
          image: busybox:1.36
          command: ["sh", "-c", "exit 1"]
EOF

echo "Scenario 17 deployed in namespace 'scenario17'. Investigate and fix."
