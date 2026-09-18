#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace taskns24 --dry-run=client -o yaml | kubectl apply -f -
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: log-app
  namespace: taskns24
spec:
  replicas: 1
  selector:
    matchLabels:
      app: log-app
  template:
    metadata:
      labels:
        app: log-app
    spec:
      containers:
        - name: log-app
          image: busybox:1.36
          command: ["sh", "-c", "while true; do echo \"$(date) app log line\" >> /var/log/app/app.log; sleep 2; done"]
          volumeMounts:
            - name: logs
              mountPath: /var/log/app
      volumes:
        - name: logs
          emptyDir: {}
EOF
