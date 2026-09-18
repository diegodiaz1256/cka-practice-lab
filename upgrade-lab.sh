#!/usr/bin/env bash
# Throwaway cluster for practising a real kubeadm upgrade.
#
# The main 'cka-practice' cluster runs the current exam version (v1.35.8) and is
# left alone. This builds a SECOND cluster one patch behind (v1.35.0) so that
# 'kubeadm upgrade plan' has something to offer and 'kubeadm upgrade apply' has
# real work to do - same motions as the exam's upgrade task.
set -euo pipefail

CLUSTER=cka-upgrade
FROM_IMAGE=kindest/node:v1.35.0
TARGET=v1.35.8
DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=lib/config.sh
. "$DIR/lib/config.sh"

usage() {
  cat <<EOF
Usage: upgrade-lab.sh <up|task|down>

  up     Create the practice cluster at v1.35.0 (takes a few minutes)
  task   Print the upgrade exercise and how it will be checked
  down   Delete it

This cluster is separate from 'cka-practice'. Your normal kubectl context is
restored when you run 'down'. While it is up, 'kubectl config use-context
kind-cka-upgrade' switches to it.
EOF
}

up() {
  if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
    echo "Cluster '$CLUSTER' already exists."
  else
    echo "Creating '$CLUSTER' at $FROM_IMAGE (1 control-plane + 1 worker)..."
    cat <<EOF | kind create cluster --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: $CLUSTER
nodes:
  - role: control-plane
    image: $FROM_IMAGE
  - role: worker
    image: $FROM_IMAGE
EOF
  fi
  kubectl --context "kind-$CLUSTER" get nodes
  echo
  task
}

task() {
  cat <<EOF

=== Upgrade exercise ===

Cluster 'kind-$CLUSTER' is running one patch behind. Upgrade the control-plane
node to $TARGET, the way the exam asks for it:

  1. kubectl config use-context kind-$CLUSTER
  2. docker exec -it $CLUSTER-control-plane bash
  3. kubeadm upgrade plan                     # see what's available
  4. Drain the control-plane node             (kubectl drain ... --ignore-daemonsets)
  5. Upgrade the kubeadm binary to $TARGET, then:
       kubeadm upgrade apply $TARGET
  6. Upgrade kubelet + kubectl on that node, restart kubelet
  7. Uncordon the node
  8. Repeat the node part (kubeadm upgrade node) on $CLUSTER-worker

Note: kind node images ship fixed binaries, so step 5/6 means fetching the
$TARGET binaries into the container - that is the part the real exam does with
apt/yum instead. The kubeadm/drain/uncordon sequence is identical.

Check your work:
  kubectl --context kind-$CLUSTER get nodes     # should show $TARGET
  docker exec $CLUSTER-control-plane kubeadm version

EOF
}

down() {
  kind delete cluster --name "$CLUSTER" 2>/dev/null || true
  kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null 2>&1 || true
  echo "Removed. Context back on kind-cka-practice."
}

case "${1:-}" in
  up) up ;;
  task) task ;;
  down) down ;;
  *) usage; exit 1 ;;
esac
