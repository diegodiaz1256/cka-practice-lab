#!/usr/bin/env bash
# Writes the kind cluster definition from cka.conf. Called by start.sh.
set -euo pipefail
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/config.sh"

sans=$(cka_cert_sans)

{
  echo "kind: Cluster"
  echo "apiVersion: kind.x-k8s.io/v1alpha4"
  echo "name: $CLUSTER_NAME"
  echo "networking:"
  echo "  apiServerAddress: \"$API_ADDRESS\""
  [ "$API_PORT" != "0" ] && echo "  apiServerPort: $API_PORT"
  if [ -n "$sans" ]; then
    echo "kubeadmConfigPatches:"
    echo "  - |"
    echo "    kind: ClusterConfiguration"
    echo "    apiServer:"
    echo "      certSANs:"
    echo "$sans" | tr ',' '\n' | while read -r s; do
      [ -n "$s" ] && echo "        - $s"
    done
  fi
  echo "nodes:"
  echo "  - role: control-plane"
  echo "    image: $NODE_IMAGE"
  echo "  - role: worker"
  echo "    image: $NODE_IMAGE"
  echo "  - role: worker"
  echo "    image: $NODE_IMAGE"
}
