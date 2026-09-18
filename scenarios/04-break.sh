#!/usr/bin/env bash
# Scenario 4: kubelet down on a worker node - node goes NotReady
set -euo pipefail
NODE=cka-practice-worker

docker exec "$NODE" systemctl stop kubelet
docker exec "$NODE" systemctl disable kubelet >/dev/null 2>&1 || true

echo "Scenario 4 applied to node '$NODE'. Investigate and fix (give it ~40s to show up)."
