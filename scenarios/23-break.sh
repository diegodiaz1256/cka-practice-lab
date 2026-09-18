#!/usr/bin/env bash
# Scenario 23: kubelet client cert path corrupted on a node - node NotReady, x509 errors
set -euo pipefail
NODE=cka-practice-worker2

docker exec "$NODE" cp /etc/kubernetes/kubelet.conf /tmp/kubelet.conf.bak
docker exec "$NODE" sed -i 's#/var/lib/kubelet/pki/kubelet-client-current.pem#/var/lib/kubelet/pki/kubelet-client-MISSING.pem#' /etc/kubernetes/kubelet.conf
docker exec "$NODE" systemctl restart kubelet

echo "Scenario 23 applied to node '$NODE'. Investigate and fix (give it ~40s to show up)."
