#!/usr/bin/env bash
# ./stop.sh            pause: stop the node containers, keep the cluster and its state
# ./stop.sh --delete   tear the cluster down completely
# Either way, ./start.sh brings it back (resuming a paused cluster, recreating a deleted one).
set -euo pipefail

DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=lib/config.sh
. "$DIR/lib/config.sh"
# shellcheck source=lib/cluster.sh
. "$DIR/lib/cluster.sh"

case "${1:-}" in
  ""|--pause|pause) mode=pause ;;
  --delete|-d|delete) mode=delete ;;
  -h|--help)
    sed -n '2,4p' "$0" | sed 's/^# \{0,1\}//'
    exit 0 ;;
  *) echo "Unknown option '$1'. Try --help." >&2; exit 1 ;;
esac

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "Cluster '$CLUSTER_NAME' does not exist, nothing to do."
  exit 0
fi

if [ "$mode" = delete ]; then
  echo "Deleting cluster '$CLUSTER_NAME'..."
  kind delete cluster --name "$CLUSTER_NAME"
  echo "Done. Run ./start.sh to recreate."
else
  cka_pause
  echo "Done. ./start.sh resumes it with everything as you left it; ./stop.sh --delete removes it."
fi
