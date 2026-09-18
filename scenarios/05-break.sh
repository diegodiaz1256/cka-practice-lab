#!/usr/bin/env bash
# Scenario 5: RBAC - ServiceAccount can't list pods, app gets Forbidden
set -euo pipefail
kubectl create namespace scenario5 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: watcher
  namespace: scenario5
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: scenario5
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: watcher-binding
  namespace: scenario5
subjects:
  - kind: ServiceAccount
    name: watcher
    namespace: scenario5
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF

echo "Scenario 5 deployed in namespace 'scenario5'. Investigate and fix."
