# Troubleshooting Exercises

"Find and fix" scenarios. Each breaks something real on the
`cka-practice` cluster. Break scripts only tell you *what namespace/node was touched*,
never *what's actually wrong* — same as the real exam, you diagnose from symptoms.
Don't peek at the answer or the `-break.sh` source until you're done or truly stuck.

## How to use
Preferred — via the manager (tracks progress in `progress.json`):
```
~/cka-practice/cka start s01     # inject the fault
# ... go fix it with kubectl, node shells, etc ...
~/cka-practice/cka pass s01      # or: cka fail s01
~/cka-practice/cka stop          # reset cluster to clean state
```
Raw scripts also work if you prefer:
```
cd ~/cka-practice/scenarios
./01-break.sh
./reset.sh
```
Run scenarios one at a time — `reset.sh` clears all of them regardless of which is active.
Node shell access (works because kind nodes are just containers):
```
docker exec -it cka-practice-worker bash
docker exec -it cka-practice-control-plane bash
```

---

### Scenario 1 — Workload
```
./01-break.sh
```
Namespace `scenario1` has a Deployment called `web`. Something's wrong with it — find it and fix it.
<details><summary>Answer</summary>
The container command is `nginx-typo` (doesn't exist) instead of `nginx`, causing CrashLoopBackOff.
Fix via `kubectl edit deployment web -n scenario1` and correct/remove the bad `command` field.
</details>

---

### Scenario 2 — Services & Networking
```
./02-break.sh
```
Namespace `scenario2` has a Deployment `api` and a Service `api-svc`. Traffic isn't reaching the pods.
<details><summary>Answer</summary>
Service selector is `app: api-backend`, pods are labeled `app: api` — mismatch, so Endpoints stay
empty. Fix with `kubectl patch service api-svc -n scenario2 -p '{"spec":{"selector":{"app":"api"}}}'`.
</details>

---

### Scenario 3 — Workloads & Scheduling
```
./03-break.sh
```
Namespace `scenario3` has a Pod `big-pod` that never schedules.
<details><summary>Answer</summary>
Requests `cpu: 100`, `memory: 500Gi` — no node has anywhere close to that allocatable.
`kubectl describe pod big-pod -n scenario3` shows it in Events. Fix by deleting and recreating
with sane requests (e.g. `cpu: 100m`, `memory: 128Mi`) — Pod resource requests are immutable.
</details>

---

### Scenario 4 — Cluster Architecture (node health)
```
./04-break.sh
```
Check `kubectl get nodes` — one of them isn't right.
<details><summary>Answer</summary>
kubelet was stopped/disabled on `cka-practice-worker`, node shows `NotReady`.
```
docker exec -it cka-practice-worker bash
systemctl status kubelet     # inactive/disabled
systemctl enable --now kubelet
```
</details>

---

### Scenario 5 — RBAC
```
./05-break.sh
```
Namespace `scenario5` has a ServiceAccount `watcher` that's supposed to be able to list Pods there, but isn't.
<details><summary>Answer</summary>
Check with `kubectl auth can-i list pods --as=system:serviceaccount:scenario5:watcher -n scenario5`
(returns `no`). The `pod-reader` Role only grants `get`/`list` on `configmaps`, not `pods`.
Fix by editing the Role to add a rule for `pods`:
`kubectl edit role pod-reader -n scenario5`.
</details>

---

### Scenario 6 — Cluster Architecture (control plane)
```
./06-break.sh
```
New pods across the cluster stay `Pending` indefinitely. Something on `cka-practice-control-plane` is broken.
<details><summary>Answer</summary>
```
kubectl get pods -n kube-system -l component=kube-scheduler
kubectl logs -n kube-system kube-scheduler-cka-practice-control-plane
```
An unknown flag `--bogus-flag=true` was injected into the scheduler's static pod manifest at
`/etc/kubernetes/manifests/kube-scheduler.yaml` on the control-plane node, crashing it. Edit that
file to remove the bad line — kubelet auto-detects the change and restarts the static pod (no
`kubectl apply`, static pods aren't API objects you edit directly). A backup is at
`/tmp/kube-scheduler.yaml.bak` on that node if you want to diff instead of hand-fixing.
</details>

---

### Scenario 7 — Workloads (images)
```
./07-break.sh
```
Namespace `scenario7` has a Deployment `cache` whose pod never comes up.
<details><summary>Answer</summary>
`kubectl describe pod` shows `ImagePullBackOff` — image is `redis:7-alpien` (typo, should be `alpine`).
Fix the image tag: `kubectl set image deployment/cache cache=redis:7-alpine -n scenario7`.
</details>

---

### Scenario 8 — Workloads & Scheduling (taints)
```
./08-break.sh
```
Namespace `scenario8` has a Pod `needs-gpu-node` stuck `Pending`.
<details><summary>Answer</summary>
`kubectl describe pod needs-gpu-node -n scenario8` Events show a taint mismatch. Node
`cka-practice-worker2` was tainted `dedicated=gpu:NoSchedule`, and the pod has no matching
toleration. Fix by adding a toleration to the pod spec, or remove the taint if it's not needed:
`kubectl taint node cka-practice-worker2 dedicated=gpu:NoSchedule-`.
</details>

---

### Scenario 9 — Storage
```
./09-break.sh
```
Namespace `scenario9` has a PVC `data-claim` and Deployment `db` using it. The pod is stuck `Pending`.
<details><summary>Answer</summary>
`kubectl get pvc data-claim -n scenario9` shows `Pending`. It requests `storageClassName: fast-ssd`,
which doesn't exist (`kubectl get storageclass` only shows `standard`). Fix by patching the PVC's
storageClassName to `standard`, or create a StorageClass named `fast-ssd` pointing at the same
provisioner (`rancher.io/local-path`).
</details>

---

### Scenario 10 — Services & Networking (NetworkPolicy)
```
./10-break.sh
```
Namespace `scenario10` has Deployment `backend` and Service `backend-svc`, both look healthy, but nothing can reach it.
<details><summary>Answer</summary>
`kubectl get networkpolicy -n scenario10` shows `deny-all-ingress` with an empty podSelector (matches
all pods) and no ingress rules — default-deny. Fix by deleting the policy, or adding an ingress rule
allowing the traffic you want, e.g. from same-namespace pods.
</details>

---

### Scenario 11 — Services & Networking (DNS)
```
./11-break.sh
```
Namespace `scenario11` has a `dns-test` pod to help you probe. DNS resolution is broken cluster-wide.
<details><summary>Answer</summary>
```
kubectl exec -n scenario11 dns-test -- nslookup kubernetes.default
kubectl get pods -n kube-system -l k8s-app=kube-dns
```
CoreDNS was scaled to 0 replicas. Fix: `kubectl scale deployment coredns -n kube-system --replicas=2`.
</details>

---

### Scenario 12 — Cluster Architecture (quotas)
```
./12-break.sh
```
Namespace `scenario12` has a Deployment `newapp` that can't get its pods running.
<details><summary>Answer</summary>
`kubectl describe deployment newapp -n scenario12` shows `FailedCreate` in Events.
`kubectl get resourcequota -n scenario12` shows `tiny-quota` capping `pods: 1`, already consumed
by the `placeholder` pod. Fix by raising the quota (`kubectl edit resourcequota tiny-quota -n
scenario12`) or deleting `placeholder` to free capacity.
</details>

---

### Scenario 13 — Workloads (probes)
```
./13-break.sh
```
Namespace `scenario13` has Deployment `web2`. The pod keeps restarting.
<details><summary>Answer</summary>
`kubectl describe pod -n scenario13` Events show liveness probe failures. The probe targets
`/healthz` on port `9999`, but nginx only listens on 80 and doesn't have that path. Fix by
correcting the probe (`kubectl edit deployment web2 -n scenario13`) — e.g. path `/` port `80`.
</details>

---

### Scenario 14 — Cluster Architecture (kubeconfig)
```
./14-break.sh
```
On node `cka-practice-control-plane`, `/etc/kubernetes/admin.conf` is affected (your local
`~/.kube/config` still works fine — this only breaks the copy on the node itself).
<details><summary>Answer</summary>
```
docker exec -it cka-practice-control-plane bash
kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes   # connection refused, port 16443
grep server /etc/kubernetes/admin.conf
```
The server port was changed from `6443` to `16443`. Fix by editing `/etc/kubernetes/admin.conf`
and correcting the port back to `6443` (or restore from `/tmp/admin.conf.bak` if present).
</details>

---

### Scenario 15 — Services & Networking
```
./15-break.sh
```
Namespace `scenario15` has Deployment `portapp` and Service `portapp-svc`. Endpoints exist but connections fail.
<details><summary>Answer</summary>
Service `targetPort: 8080` but nginx listens on 80. Endpoints populate (selector matches) but traffic
hits a closed port. Fix targetPort to 80: `kubectl edit svc portapp-svc -n scenario15`.
</details>

---

### Scenario 16 — Workloads (config)
```
./16-break.sh
```
Namespace `scenario16`, Deployment `cfgapp` pod won't start.
<details><summary>Answer</summary>
`CreateContainerConfigError` — `envFrom.configMapRef` points at ConfigMap `app-settings` that doesn't
exist. Fix by creating it: `kubectl create configmap app-settings -n scenario16 --from-literal=key=value`,
or remove the envFrom block.
</details>

---

### Scenario 17 — Workloads (Jobs)
```
./17-break.sh
```
Namespace `scenario17` has Job `batchjob` that never completes.
<details><summary>Answer</summary>
Container command is `exit 1` — always fails, `backoffLimit: 2` exhausts then Job marked Failed.
Fix the command to something that succeeds (`exit 0` / real work). Jobs are largely immutable —
delete and recreate: `kubectl delete job batchjob -n scenario17`.
</details>

---

### Scenario 18 — Workloads (secrets)
```
./18-break.sh
```
Namespace `scenario18`, Deployment `secretapp` pod won't start.
<details><summary>Answer</summary>
`CreateContainerConfigError` — `secretKeyRef` wants key `password` from Secret `db-secret`, but that
Secret only has `username`. Fix by adding the key:
`kubectl patch secret db-secret -n scenario18 -p '{"stringData":{"password":"s3cr3t"}}'`.
</details>

---

### Scenario 19 — Workloads & Scheduling (tolerations)
```
./19-break.sh
```
Namespace `scenario19`, Pod `toleration-pod` stays Pending — it *has* a toleration.
<details><summary>Answer</summary>
Node `cka-practice-worker` is tainted `special=true:NoSchedule`, but the pod's toleration has
`value: "false"` with `operator: Equal` — value mismatch, so it doesn't tolerate. Fix the toleration
value to `"true"` (or use `operator: Exists`). Pod tolerations are immutable — delete and recreate.
</details>

---

### Scenario 20 — Workloads (securityContext)
```
./20-break.sh
```
Namespace `scenario20`, Deployment `roapp` crashes on start.
<details><summary>Answer</summary>
`readOnlyRootFilesystem: true` stops nginx writing its pid file and cache dirs. Fix by either removing
that setting, or mounting emptyDir volumes at `/var/cache/nginx` and `/var/run` so the writable paths
it needs exist.
</details>

---

### Scenario 21 — Cluster Architecture (PDB)
```
./21-break.sh
```
Namespace `scenario21`. Try `kubectl drain cka-practice-worker2 --ignore-daemonsets --delete-emptydir-data` — it hangs/fails.
<details><summary>Answer</summary>
PodDisruptionBudget `pdbapp-pdb` sets `minAvailable: 5` but the Deployment only has 2 replicas — no
eviction can ever satisfy it, so drain blocks forever. Fix by lowering minAvailable (e.g. 1) or scaling
the Deployment up. Afterwards `kubectl uncordon cka-practice-worker2` (drain cordons the node).
</details>

---

### Scenario 22 — Services & Networking (readiness)
```
./22-break.sh
```
Namespace `scenario22`. Pod is Running but Service `readyapp-svc` has no endpoints.
<details><summary>Answer</summary>
`readinessProbe` does a tcpSocket check on port 81; nginx only listens on 80. Pod never becomes Ready,
so it's excluded from Service endpoints. Fix the probe port to 80.
</details>

---

### Scenario 23 — Cluster Architecture (certs/kubelet)
```
./23-break.sh
```
Node `cka-practice-worker2` goes NotReady after ~40s.
<details><summary>Answer</summary>
```
docker exec -it cka-practice-worker2 bash
systemctl status kubelet
journalctl -u kubelet -n 30       # x509 / cannot load client cert
grep client-certificate /etc/kubernetes/kubelet.conf
```
The client-certificate path in `/etc/kubernetes/kubelet.conf` was changed to a non-existent
`kubelet-client-MISSING.pem`. Fix it back to `/var/lib/kubelet/pki/kubelet-client-current.pem`, then
`systemctl restart kubelet`. Backup at `/tmp/kubelet.conf.bak` on that node.

Related real-exam skill: `kubeadm certs check-expiration` on the control-plane node, and
`kubeadm certs renew all` when certs have actually expired.
</details>

---

### Scenario 24 — Storage (accessMode)
```
./24-break.sh
```
Namespace `scenario24`: PVC `shared-claim` never binds although a PV exists.
<details><summary>Answer</summary>
PV `rwo-pv` offers `ReadWriteOnce`, the PVC asks for `ReadWriteMany` — access modes must be
compatible for binding. Fix the PVC to `ReadWriteOnce` (delete/recreate; accessModes are
immutable), or provide a PV that supports RWX.
</details>

---

### Scenario 25 — Storage (capacity)
```
./25-break.sh
```
Namespace `scenario25`: PVC `big-claim` stays Pending.
<details><summary>Answer</summary>
PV `small-pv` is 500Mi, the claim asks 10Gi. A PV only binds if its capacity is >= the
request. Recreate the claim asking <= 500Mi, or create a bigger PV in `scenario25-sc`.
</details>

---

### Scenario 26 — Storage (subPath)
```
./26-break.sh
```
Namespace `scenario26`: `siteapp` runs, but serves the default nginx page instead of the
ConfigMap content.
<details><summary>Answer</summary>
`subPath: index.htm` doesn't match the ConfigMap key `index.html`, so an empty file is
mounted over the nginx default. Fix the subPath to `index.html`.
</details>

---

### Scenario 27 — Networking (egress NetworkPolicy)
```
./27-break.sh
```
Namespace `scenario27`: DNS lookups from `dnsclient` fail, though CoreDNS is healthy.
<details><summary>Answer</summary>
NetworkPolicy `lockdown-egress` allows egress only to pods in the same namespace, which
blocks UDP/TCP 53 to CoreDNS in kube-system. Add an egress rule allowing port 53 to the
kube-system namespace (or to the kube-dns pods), e.g. a `to: namespaceSelector` block plus
`ports: [{protocol: UDP, port: 53}, {protocol: TCP, port: 53}]`.
</details>

---

### Scenario 28 — Networking (headless Service)
```
./28-break.sh
```
Namespace `scenario28`: `headless-svc` has no ClusterIP to route to.
<details><summary>Answer</summary>
The Service sets `clusterIP: None` (headless) — DNS returns pod IPs, there's no virtual IP.
`clusterIP` is immutable, so delete and recreate the Service without that field.
</details>

---

### Scenario 29 — Cluster (ServiceAccount token)
```
./29-break.sh
```
Namespace `scenario29`: `api-pod` has RBAC but no token on disk.
<details><summary>Answer</summary>
The pod sets `automountServiceAccountToken: false`, so no token is projected at
`/var/run/secrets/kubernetes.io/serviceaccount/`. Remove that field (or set it true) and
recreate the pod.
</details>

---

### Scenario 30 — Cluster (LimitRange vs ResourceQuota)
```
./30-break.sh
```
Namespace `scenario30`: `limitedapp` can't create pods, though nothing obvious is wrong
with the Deployment.
<details><summary>Answer</summary>
`kubectl describe rs -n scenario30` shows the quota rejection. LimitRange `heavy-defaults`
injects requests of 2 CPU / 2Gi into every container, but ResourceQuota `modest-quota`
caps the namespace at 500m / 512Mi — so the defaulted pod can never fit. Lower the
LimitRange defaults, raise the quota, or set explicit smaller requests on the Deployment.
</details>

---

### Scenario 31 — Cluster (cordoned nodes)
```
./31-break.sh
```
Namespace `scenario31`: `waiting-app` pods stay Pending.
<details><summary>Answer</summary>
`kubectl get nodes` shows both workers `SchedulingDisabled`. Uncordon them:
`kubectl uncordon cka-practice-worker cka-practice-worker2`.
</details>

---

### Scenario 32 — Scheduling (nodeSelector)
```
./32-break.sh
```
Namespace `scenario32`: `picky-app` won't schedule.
<details><summary>Answer</summary>
`nodeSelector: tier=platinum` matches no node. Either label a node
(`kubectl label node cka-practice-worker tier=platinum`) or drop the nodeSelector.
</details>

---

### Scenario 33 — Storage (StatefulSet volumeClaimTemplate)
```
./33-break.sh
```
Namespace `scenario33`: `statefuldb-0` never starts.
<details><summary>Answer</summary>
The volumeClaimTemplate asks for storageClassName `nvme-tier`, which doesn't exist, so the
generated PVC stays Pending. volumeClaimTemplates are immutable — delete the StatefulSet
(and its PVC) and recreate using `standard`, or create an `nvme-tier` StorageClass backed
by `rancher.io/local-path`.
</details>

---

### Scenario 34 — Cluster (apiserver certificate)
```
./34-break.sh
```
`kubectl` stops working entirely: connection refused on the API server port. Node
`cka-practice-control-plane`.
<details><summary>Answer</summary>
`kubectl` is dead, so diagnose from inside the node:
```
docker exec -it cka-practice-control-plane bash
crictl ps -a | grep apiserver          # Exited, restarting
crictl logs <container-id>             # cannot load serving certificate
ls /etc/kubernetes/pki/apiserver.*     # apiserver.crt and .key are gone
```
Reissue the pair from the cluster CA. `kubeadm certs renew` can't help here — it needs a
reachable API server to read the cluster config, and it won't generate a cert that doesn't
exist. Use the init phase instead:
```
kubeadm init phase certs apiserver
```
If you set `API_HOST` or `EXTRA_SANS` in `cka.conf`, pass them too or your kubeconfig will
fail TLS verification afterwards:
```
kubeadm init phase certs apiserver --apiserver-cert-extra-sans=<your names/IPs>
```
Then bounce the static pod (move the manifest out of `/etc/kubernetes/manifests/` and back)
and wait ~45s. Backups sit at `/tmp/apiserver.crt.bak` / `.key.bak` on that node.

Related exam skills: `kubeadm certs check-expiration`, `kubeadm certs renew <cert>` (which
does work when the API server is up — see task t53).
</details>

---

## Reset
```
./reset.sh
```
Cleans up all scenario namespaces, removes the scenario 8 taint, restores CoreDNS replicas,
restarts kubelet on the worker if stopped, and restores the kube-scheduler/admin.conf files from
backup if scenarios 6/14 are active. Safe to run anytime.
