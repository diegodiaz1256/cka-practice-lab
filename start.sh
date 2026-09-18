#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=lib/config.sh
. "$DIR/lib/config.sh"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing '$1'. See README for install steps." >&2; exit 1; }
}
need docker
need kind
need kubectl
need jq

docker info >/dev/null 2>&1 || {
  echo "Can't talk to Docker. Is it running, and is your user in the 'docker' group?" >&2
  exit 1
}

# Each kind node needs a fistful of inotify instances. When the host limit is low the
# control plane comes up fine but workers fail to join, with "inotify_init: too many
# open files" buried in their kubelet log - so check up front instead.
if [ -r /proc/sys/fs/user/max_inotify_instances ] || [ -r /proc/sys/fs/inotify/max_user_instances ]; then
  inst=$(cat /proc/sys/fs/inotify/max_user_instances 2>/dev/null || echo 0)
  watches=$(cat /proc/sys/fs/inotify/max_user_watches 2>/dev/null || echo 0)
  if [ "$inst" -lt 512 ] || [ "$watches" -lt 524288 ]; then
    echo "WARNING: inotify limits look low for kind (instances=$inst watches=$watches)."
    echo "  Worker nodes may fail to join. Raise them with:"
    echo "    sudo sysctl fs.inotify.max_user_instances=512"
    echo "    sudo sysctl fs.inotify.max_user_watches=524288"
    echo "  Persist in /etc/sysctl.d/99-kind.conf. Continuing anyway..."
    echo
  fi
fi

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "Cluster '$CLUSTER_NAME' already exists."
else
  echo "Creating cluster '$CLUSTER_NAME' ($NODE_IMAGE)..."
  bash "$DIR/lib/render-kind-config.sh" > "$DIR/.kind-config.generated.yaml"
  kind create cluster --config "$DIR/.kind-config.generated.yaml"

  echo "Creating practice namespaces and contexts..."
  for ns in dev staging prod restricted; do
    kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
    kubectl config set-context "cka-$ns" \
      --cluster="kind-$CLUSTER_NAME" --user="kind-$CLUSTER_NAME" --namespace="$ns" >/dev/null
  done
  kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null
fi

echo "Waiting for nodes to be Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=180s

# --all only covers nodes that registered, so a worker that never joined slips past it.
node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
if [ "$node_count" -lt 3 ]; then
  echo
  echo "Only $node_count of 3 nodes joined. The usual cause is the host's inotify limit;"
  echo "check with: docker exec ${CLUSTER_NAME}-worker journalctl -u kubelet -n 20"
  echo "Then: sudo sysctl fs.inotify.max_user_instances=512 && ./stop.sh && ./start.sh"
  echo
fi

# Gateway API is GA in 1.35 and on the exam, but kind doesn't ship the CRDs.
# No controller is installed - the exam tests writing correct specs, not live traffic.
if ! kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1; then
  echo "Installing Gateway API v1 CRDs..."
  kubectl apply -f \
    https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.2/standard-install.yaml \
    >/dev/null
fi

# etcdctl/etcdutl for the backup/restore exercises. etcd 3.6 moved 'snapshot restore'
# out of etcdctl into etcdutl, so both are needed.
if ! docker exec "$CONTROL_PLANE" test -x /usr/local/bin/etcdctl 2>/dev/null; then
  echo "Installing etcdctl/etcdutl on the control-plane node..."
  docker exec "$CONTROL_PLANE" sh -c '
    set -e; cd /tmp; V=v3.6.6
    curl -sL https://github.com/etcd-io/etcd/releases/download/${V}/etcd-${V}-linux-amd64.tar.gz -o e.tgz
    tar xzf e.tgz
    install -m 0755 etcd-${V}-linux-amd64/etcdctl /usr/local/bin/etcdctl
    install -m 0755 etcd-${V}-linux-amd64/etcdutl /usr/local/bin/etcdutl
    rm -rf e.tgz etcd-${V}-linux-amd64' >/dev/null
fi

# kind writes API_ADDRESS into the kubeconfig. If a hostname was configured, use that
# instead so the same file works from other machines - the cert carries both.
if [ -n "$API_HOST" ] && grep -q "server: https://$API_ADDRESS:" "$HOME/.kube/config" 2>/dev/null; then
  echo "Pointing kubeconfig at $API_HOST..."
  sed -i "s|server: https://$API_ADDRESS:|server: https://$API_HOST:|" "$HOME/.kube/config"
fi

echo "Writing a portable kubeconfig to $DIR/kubeconfig..."
kubectl config view --minify=false --flatten > "$DIR/kubeconfig"
chmod 600 "$DIR/kubeconfig"

echo
kubectl get nodes -o wide
echo
server=$(kubectl config view -o jsonpath="{.clusters[?(@.name=='kind-$CLUSTER_NAME')].cluster.server}")
echo "Cluster ready. Server: ${server:-https://$CLIENT_HOST:$API_PORT}"
echo "Start practising:  ./cka -i"
