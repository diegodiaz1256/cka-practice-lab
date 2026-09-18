#!/usr/bin/env bash
# Loads cka.conf, then cka.conf.local if present so local overrides win.
# Every script sources this rather than hardcoding host/cluster details.

CKA_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"

# shellcheck disable=SC1091
[ -f "$CKA_ROOT/cka.conf" ] && . "$CKA_ROOT/cka.conf"
# shellcheck disable=SC1091
[ -f "$CKA_ROOT/cka.conf.local" ] && . "$CKA_ROOT/cka.conf.local"

CLUSTER_NAME="${CLUSTER_NAME:-cka-practice}"
NODE_IMAGE="${NODE_IMAGE:-kindest/node:v1.35.8}"
API_ADDRESS="${API_ADDRESS:-127.0.0.1}"
API_PORT="${API_PORT:-6443}"
API_HOST="${API_HOST:-}"
EXTRA_SANS="${EXTRA_SANS:-}"

# What clients put in their kubeconfig.
CLIENT_HOST="${API_HOST:-$API_ADDRESS}"

CONTROL_PLANE="${CLUSTER_NAME}-control-plane"
WORKER1="${CLUSTER_NAME}-worker"
WORKER2="${CLUSTER_NAME}-worker2"

# Everything that belongs in the API server certificate.
cka_cert_sans() {
  local sans=""
  [ -n "$API_HOST" ] && sans="$API_HOST"
  [ "$API_ADDRESS" != "127.0.0.1" ] && sans="${sans:+$sans,}$API_ADDRESS"
  [ -n "$EXTRA_SANS" ] && sans="${sans:+$sans,}$EXTRA_SANS"
  echo "$sans"
}
