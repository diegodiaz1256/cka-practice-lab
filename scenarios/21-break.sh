#!/usr/bin/env bash
# Scenario 21: PDB blocks all evictions/drain - minAvailable exceeds replica count
set -euo pipefail
kubectl create namespace scenario21 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pdbapp
  namespace: scenario21
spec:
  replicas: 2
  selector:
    matchLabels:
      app: pdbapp
  template:
    metadata:
      labels:
        app: pdbapp
    spec:
      containers:
        - name: pdbapp
          image: nginx:1.25
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: pdbapp-pdb
  namespace: scenario21
spec:
  minAvailable: 5
  selector:
    matchLabels:
      app: pdbapp
EOF

echo "Scenario 21 deployed in namespace 'scenario21'. Investigate and fix (try: kubectl drain cka-practice-worker2 --ignore-daemonsets --delete-emptydir-data)."
