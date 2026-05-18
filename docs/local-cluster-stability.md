# Local Cluster Stability & Tuning (OrbStack)

This document captures stability-focused tuning applied to `luban-bootstrapper` when running on a **local, single-node** Kubernetes cluster (commonly OrbStack on macOS). The goal is to reduce “fragile” behavior such as cascading restarts when the node is under CPU/memory pressure or when the host sleeps.

## Why Local Clusters Feel Fragile

Local clusters differ from production:

- **Single node**: control-plane and workloads share the same CPU/memory.
- **Tight headroom**: bursts (GC, indexing, queries, image pulls) can temporarily delay HTTP/gRPC endpoints.
- **Host sleep/wake**: if the VM pauses, the control-plane stalls; controllers can lose leader election and restart.
- **Probes tuned too aggressively**: `timeoutSeconds: 1` is often fine on an uncongested node but becomes unreliable under load.

The common symptom is “my app crashes”, but the real cause is often **kubelet restarts due to probe failures**.

## Stability Symptoms Checklist

### Probe-driven restarts

Look for:

- Pod events: `Liveness probe failed`, `Readiness probe failed`, followed by `Killing`.
- Errors like `context deadline exceeded` or `Client.Timeout exceeded while awaiting headers`.

### Leader election churn

Look for:

- Controller logs: `leader election lost`
- Frequent restarts of controllers/operators (even without liveness probes).

## Recommended OrbStack Settings (macOS)

For a Mac with **16GB RAM**, a practical stable baseline is:

- OrbStack memory: **10–12GB** (avoid >12GB unless your host workload is very light)
- OrbStack CPU: **8 cores** (or close to host capacity)
- Disable pause during sleep if you expect the cluster to remain stable across sleep/wake:
  - `orbctl config set power.pause_in_sleep false`

## Probe Tuning Policy (Local Baseline)

For “always-on” local stacks, use a forgiving baseline:

- `timeoutSeconds: 5`
- `failureThreshold: 6`
- `periodSeconds: 10` (when adjustable)

This yields ~60s of tolerance before kubelet restarts a container, which dramatically reduces false positives during short stalls.

Use `startupProbe` (or chart equivalents) for slow starters. For StarRocks FE/CN we use chart-level “failure seconds” knobs instead of raw probe objects.

## Where Tuning Lives in This Repo

Some components expose probes via Helm values; others are patched post-install because the chart does not expose what we need or the objects are controller-generated.

### Argo CD

- Install flags adjusted in [argo-cd/Makefile](../argo-cd/Makefile)
  - `server.*Probe.timeoutSeconds=5`, `failureThreshold=6`
  - `repoServer.*Probe.timeoutSeconds=5`, `failureThreshold=6`

### Argo Events

- Install flags adjusted in [argo-events/Makefile](../argo-events/Makefile)
  - `controller.*Probe.timeoutSeconds=5`, `failureThreshold=6`

### Argo Workflows (server readiness)

- Post-install JSON patch in [argo-workflows/Makefile](../argo-workflows/Makefile)
- Patch file: [argo-workflows/server-probes.jsonpatch.yaml](../argo-workflows/server-probes.jsonpatch.yaml)
- Token helpers in [argo-workflows/Makefile](../argo-workflows/Makefile)
  - `make -C argo-workflows get-token` (prints the default login token)
  - `make -C argo-workflows admin-token` (creates a cluster-admin ServiceAccount + prints a `Bearer ...` token)

#### RBAC / Permission Notes (Common Gotchas)

Argo Workflows auth is Kubernetes RBAC-backed:

- Your UI token represents a Kubernetes identity (usually a ServiceAccount).
- Permissions are evaluated against the namespace you are viewing (dropdown in the UI) and the resources Argo needs (`workflows.argoproj.io`, `workflowtemplates.argoproj.io`, etc.).

Common symptoms:

- UI error like: `Permission denied, you are not allowed to list workflows in namespace "luban-ci"` when you switch the UI namespace.
  - Cause: the token identity has no `RoleBinding`/`ClusterRoleBinding` granting access in that namespace.

Ways to resolve:

- Stay within the namespace where RBAC exists (default installs typically grant permissions only in `$(ARGO_WORKFLOWS_NAMESPACE)`).
- Grant access in the target namespace by creating a `RoleBinding` that references the ServiceAccount in `$(ARGO_WORKFLOWS_NAMESPACE)`:
  - Example (admin in `luban-ci` for the server identity):
    - `kubectl -n luban-ci create rolebinding argo-workflows-server-admin --clusterrole=admin --serviceaccount=$(ARGO_WORKFLOWS_NAMESPACE):argo-workflows-server`
- For full “admin across namespaces”, use `make -C argo-workflows admin-token`, which creates a `cluster-admin` binding for a dedicated ServiceAccount.

### cert-manager

- Values file: [cert-manager/values.yaml](../cert-manager/values.yaml)
  - `webhook.livenessProbe/readinessProbe` relaxed
  - `global.leaderElection` timings increased (more tolerant to API latency)
  - controller/webhook/cainjector resource requests added (avoid starvation)

### metrics-server

- Values file: [metrics-server/values.yaml](../metrics-server/values.yaml)
  - `livenessProbe/readinessProbe` relaxed

### Kubernetes Replicator

- Values file: [kubernetes-replicator/values.yaml](../kubernetes-replicator/values.yaml)
  - `livenessProbe/readinessProbe` relaxed

### Envoy Gateway (controller)

- Post-install patch wired into [envoy-gateway/Makefile](../envoy-gateway/Makefile)
- Patch file: [envoy-gateway/envoy-gateway-probes.jsonpatch.yaml](../envoy-gateway/envoy-gateway-probes.jsonpatch.yaml)

### Gateway data plane (Envoy proxy created by Envoy Gateway)

The `luban-gateway` Deployment is generated/managed by Envoy Gateway; direct patches tend to be overwritten. The stable approach is:

- Attach an `EnvoyProxy` resource to the `GatewayClass` via `parametersRef` in [gateway/gateway.yaml](../gateway/gateway.yaml)
- Use `spec.provider.kubernetes.envoyDeployment.patch` (StrategicMerge) to relax probes for:
  - `envoy`
  - `shutdown-manager`

### Harbor

Harbor chart exposes only limited probe tuning (not sufficient for our case), so we patch the created Deployments/StatefulSets post-install.

- Patching wired into [harbor/Makefile](../harbor/Makefile)
- Patch files:
  - [harbor/probes-single-container.jsonpatch.yaml](../harbor/probes-single-container.jsonpatch.yaml)
  - [harbor/probes-registry.jsonpatch.yaml](../harbor/probes-registry.jsonpatch.yaml)
  - [harbor/probes-database.jsonpatch.yaml](../harbor/probes-database.jsonpatch.yaml)
  - [harbor/probes-redis.jsonpatch.yaml](../harbor/probes-redis.jsonpatch.yaml)

### StarRocks

- FE/CN probe windows via chart knobs in [starrocks/values.yaml](../starrocks/values.yaml)
  - `startupProbeFailureSeconds=900`
  - `livenessProbeFailureSeconds=300`
  - `readinessProbeFailureSeconds=300`
- Operator probe patch wired into [starrocks/Makefile](../starrocks/Makefile)
- Patch file: [starrocks/operator-probes.jsonpatch.yaml](../starrocks/operator-probes.jsonpatch.yaml)

### JupyterHub (user-scheduler)

The JupyterHub chart deploys a `kube-scheduler` side component (`user-scheduler`) which can be very sensitive to short probe timeouts in a local cluster.

- Patch wired into [jupyterhub/Makefile](../jupyterhub/Makefile)
- Patch file: [jupyterhub/user-scheduler-probes.jsonpatch.yaml](../jupyterhub/user-scheduler-probes.jsonpatch.yaml)

### Elastic Stack / ECK Operator

The ECK operator was observed exiting with `leader election lost` in a local single-node environment. For stability, leader election is disabled (single replica only) and resources increased.

- Values file: [elastic-stack/eck-operator-values.yaml](../elastic-stack/eck-operator-values.yaml)
  - `config.enableLeaderElection: false`
  - requests/limits increased

## Operational Guidance

### Verify probe-related instability

```bash
kubectl get events -A --sort-by=.lastTimestamp | egrep -i 'Unhealthy|Killing|liveness|readiness|startup' | tail -n 80
kubectl get pods -A -o "custom-columns=NS:.metadata.namespace,NAME:.metadata.name,RESTARTS:.status.containerStatuses[0].restartCount" --no-headers | sort -k3 -nr | head
```

### Verify node headroom

```bash
kubectl top node
kubectl top pods -A --sort-by=memory | head
```

## Notes on Post-Install JSON Patches

Most patch files use `op: replace`, which assumes:

- the target field exists
- the chart/controller keeps the same object structure

If an install starts failing after a chart upgrade, it’s often because a patch path no longer exists. In that case:

- inspect the current object (`kubectl get deploy -o yaml`)
- update the patch path(s) accordingly, or switch to a chart-supported values override where possible

## Reverting

All tuning is repository-local. To revert:

- reset the working tree, or selectively revert the tuning files listed above
- re-run the corresponding `make <component> install` targets to apply defaults again
