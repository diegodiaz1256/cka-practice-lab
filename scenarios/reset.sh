#!/usr/bin/env bash
# Force-clean any scenario leftovers and restore known-good control-plane/node state.
# Safe to run anytime, even if no scenario is active.
set -uo pipefail

# s34 removes the apiserver serving cert, which takes the API server down. Nothing
# else here works until it is back, so restore it before anything else.
if docker exec cka-practice-control-plane test -f /tmp/apiserver.crt.bak 2>/dev/null; then
  docker exec cka-practice-control-plane cp /tmp/apiserver.crt.bak /etc/kubernetes/pki/apiserver.crt
  docker exec cka-practice-control-plane cp /tmp/apiserver.key.bak /etc/kubernetes/pki/apiserver.key
  docker exec cka-practice-control-plane rm -f /tmp/apiserver.crt.bak /tmp/apiserver.key.bak
  docker exec cka-practice-control-plane sh -c 'mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kas.yaml && sleep 5 && mv /tmp/kas.yaml /etc/kubernetes/manifests/kube-apiserver.yaml'
  echo "Restoring API server certificate..."
  for _ in $(seq 1 40); do kubectl get nodes >/dev/null 2>&1 && break; sleep 3; done
fi

for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}' 2>/dev/null \
             | tr ' ' '\n' | grep -E '^scenario[0-9]+$'); do
  kubectl delete namespace "$ns" --wait=false --ignore-not-found >/dev/null 2>&1
done

# PVs and cluster-scoped leftovers from storage scenarios/tasks
for pv in rwo-pv small-pv manual-pv retain-pv; do
  kubectl delete pv "$pv" --wait=false --ignore-not-found >/dev/null 2>&1
done
for sc in scenario24-sc scenario25-sc slow-tier retain-sc fast-ssd nvme-tier growable; do
  kubectl delete storageclass "$sc" --ignore-not-found >/dev/null 2>&1
done

for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -E '^taskns|^scenario8-'); do
  kubectl delete namespace "$ns" --wait=false --ignore-not-found >/dev/null 2>&1
done

for ns in before-snapshot restore-marker; do
  kubectl delete namespace "$ns" --wait=false --ignore-not-found >/dev/null 2>&1
done
kubectl label node cka-practice-worker disktype- >/dev/null 2>&1 || true

kubectl taint node cka-practice-worker2 dedicated=gpu:NoSchedule- >/dev/null 2>&1
kubectl uncordon cka-practice-worker2 >/dev/null 2>&1
kubectl uncordon cka-practice-worker >/dev/null 2>&1
kubectl taint node cka-practice-worker special=true:NoSchedule- >/dev/null 2>&1
kubectl delete clusterrolebinding watcher-binding --ignore-not-found >/dev/null 2>&1
kubectl delete clusterrole node-reader --ignore-not-found >/dev/null 2>&1
kubectl delete priorityclass high-priority --ignore-not-found >/dev/null 2>&1
kubectl delete serviceaccount cluster-watcher -n default --ignore-not-found >/dev/null 2>&1
for gc in practice-gc shop-gc split-gc shared-gc; do
  kubectl delete gatewayclass "$gc" --ignore-not-found >/dev/null 2>&1
done
kubectl label node cka-practice-worker2 workload- >/dev/null 2>&1
kubectl annotate node cka-practice-worker2 owner- >/dev/null 2>&1
kubectl delete pod static-web-cka-practice-worker -n default --ignore-not-found >/dev/null 2>&1
docker exec cka-practice-worker rm -f /etc/kubernetes/manifests/static-web.yaml >/dev/null 2>&1
rm -f /tmp/taskns39-events.txt /tmp/pod-requests.txt 2>/dev/null
docker exec cka-practice-control-plane rm -f \
  /tmp/join-command.txt /tmp/renewed-certs.txt /tmp/upgrade-plan.txt \
  /tmp/cert-expiry.txt /tmp/kubeadm-config.yaml /tmp/etcd-backup.db >/dev/null 2>&1

kubectl scale deployment coredns -n kube-system --replicas=2 >/dev/null 2>&1

docker exec cka-practice-worker systemctl enable --now kubelet >/dev/null 2>&1

if docker exec cka-practice-worker2 test -f /tmp/kubelet.conf.bak 2>/dev/null; then
  docker exec cka-practice-worker2 cp /tmp/kubelet.conf.bak /etc/kubernetes/kubelet.conf
  docker exec cka-practice-worker2 rm -f /tmp/kubelet.conf.bak
  docker exec cka-practice-worker2 systemctl restart kubelet >/dev/null 2>&1
fi

if docker exec cka-practice-control-plane test -f /tmp/kube-scheduler.yaml.bak 2>/dev/null; then
  docker exec cka-practice-control-plane cp /tmp/kube-scheduler.yaml.bak /etc/kubernetes/manifests/kube-scheduler.yaml
  docker exec cka-practice-control-plane rm -f /tmp/kube-scheduler.yaml.bak
fi

if docker exec cka-practice-control-plane test -f /tmp/admin.conf.bak 2>/dev/null; then
  docker exec cka-practice-control-plane cp /tmp/admin.conf.bak /etc/kubernetes/admin.conf
  docker exec cka-practice-control-plane rm -f /tmp/admin.conf.bak
fi

echo "Reset done. Waiting for exercise namespaces to finish terminating..."
for _ in $(seq 1 60); do
  remaining=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}' 2>/dev/null \
    | tr ' ' '\n' | grep -cE '^scenario|^taskns|^before-snapshot$|^restore-marker$')
  [ "${remaining:-0}" -eq 0 ] && break
  sleep 2
done

echo "Waiting for nodes/scheduler/coredns to settle..."
sleep 5
kubectl get nodes
kubectl get pods -n kube-system -l component=kube-scheduler
kubectl get pods -n kube-system -l k8s-app=kube-dns
