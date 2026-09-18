#!/usr/bin/env bash
# Scenario 29: ServiceAccount token not mounted, app can't talk to the API server
set -euo pipefail
kubectl create namespace scenario29 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-caller
  namespace: scenario29
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-lister
  namespace: scenario29
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: api-caller-binding
  namespace: scenario29
subjects:
  - kind: ServiceAccount
    name: api-caller
    namespace: scenario29
roleRef:
  kind: Role
  name: pod-lister
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: Pod
metadata:
  name: api-pod
  namespace: scenario29
spec:
  serviceAccountName: api-caller
  automountServiceAccountToken: false
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

echo "Scenario 29 deployed in namespace 'scenario29'. Pod 'api-pod' must be able to read its ServiceAccount token at /var/run/secrets/kubernetes.io/serviceaccount/token. Investigate and fix."
