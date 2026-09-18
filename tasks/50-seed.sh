#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace taskns50 --dry-run=client -o yaml | kubectl apply -f -
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: v1
  namespace: taskns50
spec:
  replicas: 1
  selector:
    matchLabels:
      app: v1
  template:
    metadata:
      labels:
        app: v1
    spec:
      containers:
        - name: v1
          image: nginx:1.25
---
apiVersion: v1
kind: Service
metadata:
  name: v1-svc
  namespace: taskns50
spec:
  selector:
    app: v1
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: v2
  namespace: taskns50
spec:
  replicas: 1
  selector:
    matchLabels:
      app: v2
  template:
    metadata:
      labels:
        app: v2
    spec:
      containers:
        - name: v2
          image: nginx:1.25
---
apiVersion: v1
kind: Service
metadata:
  name: v2-svc
  namespace: taskns50
spec:
  selector:
    app: v2
  ports:
    - port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: split-gc
spec:
  controllerName: example.net/gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: split-gw
  namespace: taskns50
spec:
  gatewayClassName: split-gc
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: Same
EOF
