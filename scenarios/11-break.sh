#!/usr/bin/env bash
# Scenario 11: CoreDNS down - in-cluster DNS resolution fails
set -euo pipefail
kubectl create namespace scenario11 --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl scale deployment coredns -n kube-system --replicas=0

kubectl run dns-test --image=busybox:1.36 -n scenario11 --restart=Never -- sleep 3600 >/dev/null

echo "Scenario 11 applied in namespace 'scenario11'. A 'dns-test' pod is there to help you probe. Investigate and fix."
