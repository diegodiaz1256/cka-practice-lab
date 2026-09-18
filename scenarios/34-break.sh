#!/usr/bin/env bash
# Scenario 34: the apiserver serving cert is gone, so the API server won't start.
# Recovery is to reissue it from the cluster CA with kubeadm.
set -euo pipefail
CP=cka-practice-control-plane

docker exec "$CP" cp /etc/kubernetes/pki/apiserver.crt /tmp/apiserver.crt.bak
docker exec "$CP" cp /etc/kubernetes/pki/apiserver.key /tmp/apiserver.key.bak
docker exec "$CP" rm -f /etc/kubernetes/pki/apiserver.crt /etc/kubernetes/pki/apiserver.key

# Bounce the static pod so it tries (and fails) to start without the cert.
docker exec "$CP" sh -c 'mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kas.yaml && sleep 6 && mv /tmp/kas.yaml /etc/kubernetes/manifests/kube-apiserver.yaml'

echo "Scenario 34 applied to node '$CP'. Investigate and fix (give the API server ~60s to settle)."
