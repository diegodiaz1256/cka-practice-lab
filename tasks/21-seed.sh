#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace before-snapshot --dry-run=client -o yaml | kubectl apply -f -
