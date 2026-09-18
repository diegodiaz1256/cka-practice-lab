#!/usr/bin/env bash
# Scenario 6: Control-plane static pod misconfigured - kube-scheduler down (bad flag)
set -euo pipefail
CP=cka-practice-control-plane

docker exec "$CP" cp /etc/kubernetes/manifests/kube-scheduler.yaml /tmp/kube-scheduler.yaml.bak
docker exec "$CP" sed -i 's#--leader-elect=true#--leader-elect=true\n    - --bogus-flag=true#' /etc/kubernetes/manifests/kube-scheduler.yaml

echo "Scenario 6 applied to node '$CP'. Investigate and fix."
