#!/usr/bin/env bash
# Scenario 14: kubeconfig on the control-plane node points to the wrong port (admin.conf corrupted)
set -euo pipefail
CP=cka-practice-control-plane

docker exec "$CP" cp /etc/kubernetes/admin.conf /tmp/admin.conf.bak
docker exec "$CP" sed -i 's/:6443/:16443/' /etc/kubernetes/admin.conf

echo "Scenario 14 applied to node '$CP'. Its /etc/kubernetes/admin.conf is affected (not your local ~/.kube/config). Investigate and fix."
