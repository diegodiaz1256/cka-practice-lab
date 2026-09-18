# CKA Lab

89 hands-on exercises for the Certified Kubernetes Administrator exam, run against a
local 3-node Kubernetes cluster. Every exercise is graded automatically by a real
`kubectl` check, and there is a timed mock exam that mirrors the real format.

Kubernetes v1.35.8, matching the version the CKA exam is currently on.

---

## Setup

### 1. Docker

You need Docker, and your user must be able to use it without `sudo`.

```bash
# Debian / Ubuntu
sudo apt update && sudo apt install -y docker.io
sudo usermod -aG docker "$USER"   # log out and back in afterwards
docker run --rm hello-world       # should succeed without sudo
```

macOS: install Docker Desktop or Colima (`brew install colima && colima start`).

### 2. kind, kubectl, jq

```bash
# kind
curl -Lo /tmp/kind https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-amd64
chmod +x /tmp/kind && sudo install -m 0755 /tmp/kind /usr/local/bin/kind

# kubectl
curl -Lo /tmp/kubectl "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x /tmp/kubectl && sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl

# jq (the exercise manager needs it)
sudo apt install -y jq
```

macOS: `brew install kind kubectl jq`.

Optional but nicer menus — the tool falls back to plain prompts without them:
```bash
sudo apt install -y gum fzf      # or: brew install gum fzf
```

### 3. Raise inotify limits (Linux)

Each kind node consumes inotify instances. On the common default of 128, the control
plane starts but **worker nodes silently fail to join**:

```bash
sudo sysctl fs.inotify.max_user_instances=512
sudo sysctl fs.inotify.max_user_watches=524288

# make it stick across reboots
echo -e "fs.inotify.max_user_instances=512\nfs.inotify.max_user_watches=524288" \
  | sudo tee /etc/sysctl.d/99-kind.conf
```

`start.sh` warns if these look too low. Not needed on macOS.

### 4. Start the cluster

```bash
git clone <this-repo> cka-lab && cd cka-lab
./start.sh
```

First run pulls node images and takes a few minutes. When it finishes:

```bash
./cka -i
```

That is the whole setup. Defaults create the cluster on `127.0.0.1` — nothing to
configure for local use.

---

## Reaching the cluster from another machine

Only needed if you want to practise from a laptop while the cluster runs on a server.

Copy `cka.conf` to `cka.conf.local` (gitignored) and set:

```bash
API_ADDRESS=10.0.0.5            # an address on the cluster host
API_HOST=cka.internal           # optional DNS name clients will use
EXTRA_SANS=                     # any other names/IPs it is reachable by
```

Then `./start.sh`. `API_HOST` and `EXTRA_SANS` go into the API server certificate, so
`kubectl` verifies TLS properly instead of needing `--insecure-skip-tls-verify`.

Copy `./kubeconfig` to the other machine — it is self-contained (CA and client cert
embedded):

```bash
export KUBECONFIG=~/kubeconfig
kubectl get nodes
```

That file is **cluster-admin with no expiry**. Fine on a private network; do not put it
anywhere public. It is gitignored.

---

## Using it

```bash
./cka -i          # interactive menu - start here
```

Two kinds of exercise:

- **Break-and-fix** (34) — the tool sabotages your cluster. You are told only which
  namespace or node is affected, never what was done. Diagnose with `kubectl` and repair
  it. Answer keys in `scenarios/EXERCISES.md`, but try first.
- **Build** (55) — a written spec to implement. Some start from scratch, others hand you
  existing resources to modify or wire together, which is how the real exam usually
  frames things.

Each is tagged `easy` (one concept), `medium` (two combined) or `hard` (components
interacting, or node-level work). The picker asks for a level first, so you can drill one
tier at a time.

Direct commands, if you prefer them to the menu:

```bash
./cka list                # everything, with what you've solved
./cka start s07           # begin a break-and-fix exercise
./cka start t12           # begin a build exercise
./cka check               # grade what you're working on
./cka stop                # clean the cluster, move on
./cka status              # progress by exam topic and difficulty
```

Scenario titles stay hidden until solved — they name the fault, which would give the
answer away. `./cka list all reveal` shows them if you want to browse.

### Mock exam

```bash
./cka exam start     # 16-20 tasks, 2h clock, drawn fresh each time
./cka exam next      # move to the next task
./cka exam status    # time remaining
./cka exam finish    # stop the clock, see the score
```

Matches the real format: task count and domain mix vary per sitting, nothing is revealed
while you work, 66% to pass. The final report shows your score, time used, and which
topics you lost points in.

Each task is graded the moment you move off it — the cluster only holds one exercise at a
time, so it has to be checked before teardown. Tasks you never reach count as wrong.

---

## Coverage

Weighted to the published exam blueprint:

| Domain | Exercises |
|---|---|
| Cluster Architecture, Installation & Configuration | 25 |
| Workloads & Scheduling | 25 |
| Services & Networking | 22 |
| Storage | 12 |

Includes the newer exam material: **Gateway API** (GA in 1.35 — GatewayClass, HTTPRoute
attachment, weighted splitting, cross-namespace `ReferenceGrant`), **native sidecars**
(`initContainer` with `restartPolicy: Always`), etcd **backup and restore**, and
**kubeadm** work (join tokens, certificate renewal, upgrades).

The Gateway API CRDs are installed but no controller runs — the exam grades whether your
specs are correct, not live traffic.

### kubeadm upgrades

Upgrading needs a cluster that is behind, so it gets its own throwaway one:

```bash
./upgrade-lab.sh up      # second cluster, one patch back
./upgrade-lab.sh task    # the drill
./upgrade-lab.sh down    # remove it
```

Your main cluster is untouched. Task `t55` grades the result. Note that kind node images
ship fixed binaries, so replacing them differs from `apt`/`yum` on the real exam — the
`kubeadm`/drain/uncordon sequence is the same.

---

## Cluster lifecycle

```bash
./start.sh     # create if missing, wait for Ready, refresh kubeconfig
./stop.sh      # delete the cluster entirely
./cka stop     # just clean up after an exercise (keeps the cluster)
```

`./cka stop` restores everything an exercise touched: namespaces, node taints and labels,
cordons, CoreDNS replicas, control-plane manifests and certificates. Safe to run anytime.

Progress lives in `progress.json` (gitignored). `./cka reset-progress` clears it.

---

## Known limitations

- **No metrics-server**, so `kubectl top` does not work and the HPA exercise only checks
  that your spec is correct, not that it scales.
- **Upgrade binaries** are fetched by hand in the upgrade lab rather than through a
  package manager, because kind images pin their versions.
- **Running the upgrade lab alongside the main cluster** means six kind nodes at once.
  If workers fail to join, it is almost always the inotify limit above.

---

## Layout

```
cka                    exercise manager
cka.conf               configuration (copy to cka.conf.local to override)
start.sh / stop.sh     cluster lifecycle
upgrade-lab.sh         separate cluster for kubeadm upgrade practice
lib/                   config loader, kind config generator, menu helpers
scenarios/             break-and-fix: metadata, fault injectors, answer keys, reset
tasks/                 build exercises: metadata and pre-seeded resources
```

Adding your own exercise means appending an entry to `scenarios/scenarios.json` or
`tasks/tasks.json` — an `id`, `level`, `domain`, `title`, and a `verify` command that
exits 0 when the work is correct. Break-and-fix exercises also need a matching
`scenarios/NN-break.sh`.
