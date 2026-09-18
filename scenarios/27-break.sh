#!/usr/bin/env bash
# Scenario 27: NetworkPolicy egress-deny stops pods reaching CoreDNS, so DNS fails in one namespace
set -euo pipefail
kubectl create namespace scenario27 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl run dnsclient --image=busybox:1.36 -n scenario27 --restart=Never -- sleep 3600 >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: lockdown-egress
  namespace: scenario27
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector: {}
EOF

echo "Scenario 27 deployed in namespace 'scenario27'. A 'dnsclient' pod is there to probe with. Investigate and fix."
