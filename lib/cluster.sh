#!/usr/bin/env bash
# Pause and resume the kind node containers, keeping the cluster and all its state.
# Sourced by start.sh, stop.sh and cka.
# shellcheck source=config.sh
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/config.sh"

_cka_filter="label=io.x-k8s.kind.cluster=$CLUSTER_NAME"

cka_nodes()         { docker ps -a --filter "$_cka_filter" --format '{{.Names}}' | sort; }
cka_running_nodes() { docker ps    --filter "$_cka_filter" --format '{{.Names}}' | sort; }
cka_stopped_nodes() { docker ps -a --filter "$_cka_filter" --filter status=exited --format '{{.Names}}' | sort; }

cka_pause() {
  local running n
  running=$(cka_running_nodes)
  if [ -z "$running" ]; then
    echo "Cluster '$CLUSTER_NAME' has no running nodes."
    return 0
  fi
  echo "Pausing '$CLUSTER_NAME' (cluster and its state are kept)..."
  # Workers first, control plane last, so workers don't spend shutdown retrying a dead API.
  for n in $(echo "$running" | grep -v -- "-control-plane$" || true); do
    docker stop "$n" >/dev/null && echo "  stopped $n"
  done
  if echo "$running" | grep -qx "$CONTROL_PLANE"; then
    # The kind control plane never exits on its own inside the grace period - even at 60s
    # it is SIGKILLed (exit 137) - so a longer timeout only makes pausing slow. That is
    # safe: etcd fsyncs its WAL before acknowledging writes and recovers on start.
    docker stop "$CONTROL_PLANE" >/dev/null && echo "  stopped $CONTROL_PLANE"
  fi
}

cka_resume() {
  local n i
  echo "Resuming '$CLUSTER_NAME'..."
  docker start "$CONTROL_PLANE" >/dev/null
  # Docker hands out a new host port on restart when the API port is ephemeral
  # (API_PORT=0), so re-read it into the kubeconfig.
  kind export kubeconfig --name "$CLUSTER_NAME" >/dev/null 2>&1 || true
  for i in $(seq 1 60); do
    kubectl --context "kind-$CLUSTER_NAME" get --raw=/readyz >/dev/null 2>&1 && break
    sleep 3
  done
  for n in $(cka_stopped_nodes | grep -v -- "-control-plane$" || true); do
    docker start "$n" >/dev/null && echo "  started $n"
  done
}
