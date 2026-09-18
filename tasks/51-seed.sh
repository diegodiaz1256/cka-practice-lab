#!/usr/bin/env bash
set -euo pipefail
for ns in taskns51-gw taskns51-app; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done
cat <<'EOF' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: shared-gc
spec:
  controllerName: example.net/gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shared-gw
  namespace: taskns51-gw
spec:
  gatewayClassName: shared-gc
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: remote
  namespace: taskns51-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: remote
  template:
    metadata:
      labels:
        app: remote
    spec:
      containers:
        - name: remote
          image: nginx:1.25
---
apiVersion: v1
kind: Service
metadata:
  name: remote-svc
  namespace: taskns51-app
spec:
  selector:
    app: remote
  ports:
    - port: 80
EOF
