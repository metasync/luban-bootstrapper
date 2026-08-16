# Luban Kubernetes Bootstrapper for CI/CD Tools

This repository provides Makefile-based tooling to install and manage a comprehensive GitOps and workflow stack on a Kubernetes cluster. It is optimized for local development using **OrbStack** on macOS, but can be adapted for other environments.

The stack includes:

- **Core CI/CD stack (installed via `make devops`)**
  - **Argo Workflows** (Workflow orchestration)
  - **Argo CD** (GitOps application delivery)
  - **Argo Events** (Event-driven dependency manager)
  - **Harbor** (Container Registry)
  - **kpack** (Cloud Native Buildpacks for Kubernetes)
  - **Kubernetes Replicator** (Secret/ConfigMap replication)
  - **metrics-server** (Resource metrics API for `kubectl top`)
  - **Envoy Gateway + Gateway API** (Modern Ingress and Traffic Management)
  - **cert-manager** (TLS certificate management with a local CA)

- **Optional stack components (installed separately)**
  - **Workspace**: **JupyterHub** (Multi-user Notebook Platform)
  - **Data platform**: **MinIO** (S3-compatible object storage) + **StarRocks (shared-data)** (High-performance Analytical Database)
  - **Observability alternatives** (pick one or coexist):
    - **Elastic Stack (ECK)** → Fleet-managed APM, Elasticsearch, Kibana
    - **OpenObserve** → Logs, Metrics, Traces, Dashboards backed by Luban MinIO S3 (recommended low-footprint alternative)

## Prerequisites

- **macOS** (Optimized for OrbStack domains)
- **Kubernetes Cluster** (Tested with [OrbStack](https://orbstack.dev/))
- **Internet Access** (To pull Helm charts and container images)
- `envsubst` (used to render Gateway/HTTPRoute templates; comes with `gettext`)
- Local stability tuning guide: [docs/local-cluster-stability.md](./docs/local-cluster-stability.md)

The following CLI tools can be installed automatically via `make cli`:
- `kubectl`
- `helm`
- `pack`
- `kp`
- `argo`

## Layout

- **[Makefile](./Makefile)**: Root orchestration. Installs infrastructure first, then applications.
- **[Makefile.env](./Makefile.env)**: Shared configuration (versions, namespaces, domains).
- **[cli/](./cli/)**: CLI installation logic (pack, kp, helm, kubectl).

### Core CI/CD stack (`make devops`)

- **[argo-workflows/](./argo-workflows/)**: Argo Workflows Helm install & Gateway config. See [component README](./argo-workflows/README.md).
- **[argo-cd/](./argo-cd/)**: Argo CD Helm install & Gateway config.
- **[argo-events/](./argo-events/)**: Argo Events Helm install.
- **[harbor/](./harbor/)**: Harbor Helm install & Gateway config. See [component README](./harbor/README.md).
- **[cert-manager/](./cert-manager/)**: cert-manager Helm install.
- **[kubernetes-replicator/](./kubernetes-replicator/)**: Kubernetes Replicator Helm install.
- **[metrics-server/](./metrics-server/)**: metrics-server Helm install (enables `kubectl top`).
- **[envoy-gateway/](./envoy-gateway/)**: Envoy Gateway Helm OCI install.
- **[gateway/](./gateway/)**: Gateway API resources (GatewayClass, Gateway, Local CA). See [component README](./gateway/README.md).
- **[kpack/](./kpack/)**: kpack raw manifest install.

### Optional components

- **[jupyterhub/](./jupyterhub/)**: JupyterHub Helm install & Gateway config. See [component README](./jupyterhub/README.md).
- **[keycloak/](./keycloak/)**: Shared Keycloak identity provider for platform services via the upstream Keycloak Operator. See [component README](./keycloak/README.md).
- **[minio/](./minio/)**: MinIO Helm install & Gateway config.
- **[starrocks/](./starrocks/)**: StarRocks Operator Helm install (shared-data; requires MinIO).
- **[elastic-stack/](./elastic-stack/)**: Elastic Stack (Elasticsearch + Kibana) via ECK Operator. See [component README](./elastic-stack/README.md).
- **[openobserve/](./openobserve/)**: OpenObserve (Logs, Metrics, Traces, Dashboards) — low-footprint observability, S3-backed via Luban MinIO.

### Component Docs

- **Infrastructure**: [gateway](./gateway/README.md)
- **CI/CD**: [argo-workflows](./argo-workflows/README.md), [harbor](./harbor/README.md)
- **Workspace and identity**: [jupyterhub](./jupyterhub/README.md), [keycloak](./keycloak/README.md)
- **Observability**: [elastic-stack](./elastic-stack/README.md)

## Configuration

Shared configuration lives in [Makefile.env](./Makefile.env). You can customize:

- **Component Versions**:
  - Argo Workflows (App v4.0.5)
  - Argo CD (App v3.3.6)
  - Argo Events (App v1.9.10)
  - Harbor (App v2.14.3)
  - JupyterHub (App v5.4.4)
  - Keycloak (Operator/App 26.4.5)
  - MinIO (Image RELEASE.2025-10-15T17-29-55Z)
  - StarRocks Operator (App v1.11.4)
  - **OpenObserve (Chart 0.92.0 / App v0.92.0)**
  - kpack (v0.17.1)
  - Kubernetes Replicator (v2.12.3)
  - metrics-server (App 0.8.0)
  - Envoy Gateway (v1.7.1)
  - cert-manager (v1.20.1)
- **CLI Versions**:
  - Helm (v4.0.5)
  - Kubectl (v1.35.0)
  - Pack (v0.39.1)
  - kp (v0.13.1)
- **Namespaces**: Define where each component is installed.
- **Domains**:
  - `K8S_DOMAIN` (default: `luban.k8s.orb.local`)
  - `LUBAN_PUBLIC_DOMAIN` (default: `luban.metasync.cc`)
  - `APPS_DOMAIN` (default: `apps.k8s.orb.local`)
  - `APPS_PUBLIC_DOMAIN` (default: `apps.metasync.cc`)
  - `LETSENCRYPT_EMAIL` (default: `ci@metasync.cc`)
  - `ARGO_WORKFLOWS_HOST` (`argo-workflows.luban.k8s.orb.local`)
  - `ARGO_CD_HOST` (`argocd.luban.k8s.orb.local`)
  - `HARBOR_HOST` (`harbor.luban.k8s.orb.local`)
  - `KEYCLOAK_HOST` (`idp.apps.k8s.orb.local`)

## Installation

### 1. Configure Secrets (Important)

**Prerequisite:** You must own a public domain (e.g., `your-company.com`) managed by Cloudflare.

To enable public access via Cloudflare, you must provide your Cloudflare API Token.

1. Create a file `secrets/cloudflare.env` (this file is git-ignored).
2. Add your token:
   ```bash
   CLOUDFLARE_API_TOKEN=your-token-here
   ```
   *Note: The token requires `Zone:DNS:Edit` permissions for your domain.*

#### MinIO (Required for StarRocks shared-data)

StarRocks is configured to run in **shared-data** mode (FE + CN), which requires an S3-compatible object store.
This repo installs **MinIO** separately and stores its credentials in a Kubernetes Secret created from a local env file.

This project uses the legacy `minio/minio` Helm chart (Chart v5.4.0) but pins the **server image** to `RELEASE.2025-10-15T17-29-55Z`. Since MinIO no longer publishes container images for some newer tags, the image may need to be built locally during installation.

1. Create a file `secrets/minio.env` (this file is git-ignored).
2. Add the required keys:
   ```bash
   MINIO_ROOT_USER=your-minio-user
   MINIO_ROOT_PASSWORD=your-minio-password
   ```
3. Ensure you have `git`, `go`, and Docker available if a local image build is required.
3. Install MinIO first, then StarRocks (or install both via `make data-platform`):
   ```bash
   make minio
   make minio-version
   make starrocks
   ```

MinIO Console hostnames:
- Local: `https://minio-console.<K8S_DOMAIN>`
- Public: `https://minio-console.<LUBAN_PUBLIC_DOMAIN>`

MinIO Console credentials are `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` from `secrets/minio.env`.

### 2. Install CLIs

Ensure you have the necessary tools installed:

```bash
make cli
```
Or install them individually: `make helm-cli`, `make kubectl-cli`, `make pack-cli`, `make kp-cli`.

### 3. Install the Core CI/CD stack

To install base infrastructure plus all default CI/CD components:

```bash
make devops
```

If you only want the base cluster infrastructure:

```bash
make infra
```

`make infra` installs:
- cert-manager
- Kubernetes Replicator
- metrics-server (so `kubectl top` works)
- Envoy Gateway + Gateway API resources

### 4. Install optional components

```bash
make workspace
make keycloak
make data-platform
make observability
```

Elastic Stack installs Fleet-managed APM by default:

```bash
make elastic-stack
```

If you only want Elasticsearch + Kibana:

```bash
make elastic-stack-core
```

Or install them individually:

```bash
make jupyterhub
make keycloak
make minio
make starrocks
```

### 5. Install OpenObserve (lightweight observability alternative to Elastic Stack)

**OpenObserve** provides logs/metrics/traces + dashboards on Luban, backed by **Luban MinIO S3** (run `make minio` first, per prereq step 0). Default footprint is ~9 pods / 30 Gi of PVC cache, compared to ~25 pods / 100 Gi of Elastic Stack.

Before install:
0. Ensure **MinIO is installed** (`make minio`). OpenObserve writes its data to an S3 bucket in Luban's managed MinIO; the install step will crash-loop if `minio.minio.svc.cluster.local:9000` is unreachable.
1. Ensure `secrets/minio.env` exists (root credentials used to create/write the `openobserve` S3 bucket).
2. Optionally create `secrets/openobserve.env` to override the default root creds:
   ```bash
   OO_ROOT_USER_EMAIL=you@your-company.com
   OO_ROOT_USER_PASSWORD='YourStrongPassword!1'
   ```

Install:

```bash
make openobserve
```

After install:
- UI local: `https://openobserve.<K8S_DOMAIN>` (default: `https://openobserve.luban.k8s.orb.local`)
- UI public: `https://openobserve.<LUBAN_PUBLIC_DOMAIN>`
- Default login: `root@example.com` / `Complexpass#123` (unless overridden in `secrets/openobserve.env`)
- OTLP HTTP endpoint local: `http://openobserve-router.openobserve.svc.cluster.local:5080/api/default/otlp`
- OTLP HTTP endpoint public: `https://openobserve.<K8S_DOMAIN>/api/default/otlp`

**Switching Luban CI OTLP backends between OpenObserve ↔ Elastic Stack** is documented inline in `luban-ci/manifests/config/luban-config.yaml`:
- Both backends are commented-out examples in the `otel_exporter_otlp_endpoint` block.
- Uncomment the one you want, then add the matching `otel_exporter_otlp_headers` in a **secret-backed workspace overlay** (never plaintext the creds in the shared configmap).
- OpenObserve expects Basic auth; Elastic Fleet APM expects a Bearer secret token.

## Accessing the UIs

The stack uses Envoy Gateway to expose UIs via HTTPS. The gateway (`luban-gateway`) supports wildcard subdomains for both local development and public access.

| Component | Local URL | Public URL | Notes |
|-----------|-----------|------------|-------|
| **Argo Workflows** | `https://argo-workflows.<K8S_DOMAIN>` | `https://argo-workflows.<LUBAN_PUBLIC_DOMAIN>` | Requires Token |
| **Argo CD** | `https://argocd.<K8S_DOMAIN>` | `https://argocd.<LUBAN_PUBLIC_DOMAIN>` | User: `admin` |
| **Harbor** | `https://harbor.<K8S_DOMAIN>` | `https://harbor.<LUBAN_PUBLIC_DOMAIN>` | User: `admin` |
| **JupyterHub** | `https://jupyterhub.<K8S_DOMAIN>` | `https://jupyterhub.<LUBAN_PUBLIC_DOMAIN>` | Any User |
| **Keycloak** | `https://idp.<APPS_DOMAIN>` | `https://idp.<APPS_PUBLIC_DOMAIN>` | User: bootstrap admin; browser OIDC redirects use the public host by default |
| **MinIO Console** | `https://minio-console.<K8S_DOMAIN>` | `https://minio-console.<LUBAN_PUBLIC_DOMAIN>` | User: `MINIO_ROOT_USER` |
| **StarRocks FE** | `https://starrocks.<K8S_DOMAIN>` | `https://starrocks.<LUBAN_PUBLIC_DOMAIN>` | User: `root` (empty password) |
| **Kibana** | `https://kibana.<K8S_DOMAIN>` | `https://kibana.<LUBAN_PUBLIC_DOMAIN>` | User: `elastic` |
| **OpenObserve** | `https://openobserve.<K8S_DOMAIN>` | `https://openobserve.<LUBAN_PUBLIC_DOMAIN>` | Default user: `root@example.com` (OTLP requires Basic auth or ingestion token) |

New services can be exposed by binding an `HTTPRoute` to the `luban-local` listener on `luban-gateway` with a `*.<K8S_DOMAIN>` hostname (or `luban-public` for `*.<LUBAN_PUBLIC_DOMAIN>`).

Applications can be exposed using the `*.<APPS_DOMAIN>` (local) or `*.<APPS_PUBLIC_DOMAIN>` (public) wildcard domains.

### Authentication

**Argo Workflows:**
The installation generates a `workflow-runner` service account and a token secret. To retrieve the token for login:

```bash
make -C argo-workflows get-token
```
Copy the output and paste it into the UI login prompt.

For SSO-based login, the installation also creates a `user-default-login` ServiceAccount (matches all users; no RBAC by default). Access is granted via delegated RBAC in target namespaces.

**Argo CD:**
To retrieve the initial `admin` password:

```bash
make -C argo-cd get-init-secret
```

To change the `admin` password (interactive):

```bash
make -C argo-cd change-password
```

**Harbor:**
To retrieve the initial `admin` password:

```bash
make -C harbor get-password
```

**Keycloak:**
To retrieve the bootstrap admin password:

```bash
make -C keycloak get-admin-password
```

The local `idp.<APPS_DOMAIN>` route is still useful for direct cluster access, but Keycloak advertises the canonical public hostname by default. Browser login and OIDC discovery therefore still depend on `idp.<APPS_PUBLIC_DOMAIN>` being reachable unless you override `KEYCLOAK_CANONICAL_HOST`.

**Kibana (Elastic Stack via ECK):**

Kibana is configured with `server.publicBaseUrl` (via `KIBANA_PUBLIC_BASE_URL`) so it can generate correct absolute URLs when running behind the Gateway.

- Default: `KIBANA_PUBLIC_BASE_URL=https://kibana.<K8S_DOMAIN>`
- If you mainly use the public domain, set: `KIBANA_PUBLIC_BASE_URL=https://kibana.<LUBAN_PUBLIC_DOMAIN>`

Username is `elastic`. To get the password:

```bash
make -C elastic-stack get-elastic-password
```

**APM (Fleet-managed, via Fleet Server):**

`make observability` installs APM in Fleet-managed mode by default.

APM endpoint inside the cluster:

- `http://apm.elastic-stack.svc:8200`

Note: This in-cluster endpoint is plain HTTP (TLS is terminated at the Gateway for external access).

APM URLs (via Gateway):

- Local: `https://apm.<K8S_DOMAIN>`
- Public: `https://apm.<LUBAN_PUBLIC_DOMAIN>`

To get authentication credentials for APM agents:

- Kibana → Fleet → Agent policies → `eck-agent` → APM integration
  - Use a **Secret token** or **API key** (recommended) from the integration settings.

Install it with:

```bash
make elastic-stack
```

**StarRocks:**
The FE HTTP endpoint is protected by HTTP Basic Auth. Default user is `root` with an empty password.

To connect via SQL clients (e.g. DBeaver), use the MySQL protocol on FE port `9030`.

Example JDBC URLs:
- LoadBalancer: get the FE IP via `kubectl -n starrocks get svc kube-starrocks-fe-service` then use `jdbc:mysql://<fe-ip>:9030`
- Port-forward: `kubectl -n starrocks port-forward svc/kube-starrocks-fe-service 9030:9030` then `jdbc:mysql://127.0.0.1:9030`

### DNS & TLS

- **DNS**:
  - **Local**:
    - **OrbStack**: Automatically resolves `*.k8s.orb.local` to your cluster.
    - **Other**: Add entries to `/etc/hosts` pointing to the Gateway IP:
      ```
      <gateway-ip> argo-workflows.<K8S_DOMAIN> argocd.<K8S_DOMAIN> harbor.<K8S_DOMAIN> jupyterhub.<K8S_DOMAIN> minio-console.<K8S_DOMAIN> starrocks.<K8S_DOMAIN>
      ```
  - **Public**: Cloudflare manages `*.<LUBAN_PUBLIC_DOMAIN>`.
- **TLS**:
  - **Local**: A local CA is generated in the `gateway` namespace.
    - To trust the CA, extract the certificate:
      ```bash
      make -C gateway get-local-ca-crt > local-ca.crt
      ```
    - Import `local-ca.crt` into your Keychain / Browser trust store.
  - **Public**: Let's Encrypt (Staging/Prod) via DNS-01 challenge (Cloudflare).
  - Certificate rotation policy:
    - Leaf certs (Argocd/Workflows): duration `2160h` (90d), renewBefore `360h` (15d)
    - Local CA: duration `43800h` (5y), renewBefore `720h` (30d)
    - Values use Go `time.Duration` format (h/m/s), not `d`.

## Verification

**Argo Workflows:**
Submit a "Hello World" workflow:

```bash
# Submit a workflow using the installed version examples
kubectl -n argo create -f https://github.com/argoproj/argo-workflows/raw/v4.0.5/examples/hello-world.yaml

# Check status
kubectl -n argo get workflows
```

**Argo CD:**
Login to the UI and check that the status is "Healthy".

**Harbor:**
Login to the UI and create a new project.

**JupyterHub:**
Login with any username/password (dummy auth).

## Uninstalling

To remove everything (apps, infra, and namespaces):

```bash
make uninstall-workspace
make uninstall-data-platform
make uninstall-observability   # Elastic Stack only — matches `make observability`
make uninstall-observability-all   # Elastic Stack + OpenObserve, full observability wipe
make uninstall-openobserve     # only uninstall *just* OpenObserve, keep Elastic (if installed)
make uninstall-devops
make uninstall-infra
```

These targets ensure a clean slate by removing namespaces (`argo`, `argocd`, `envoy-gateway-system`, etc.) to prevent issues with lingering resources.

### Graceful PVC / dangling-PV cleanup — the `PURGE_DATA` flag

**All component uninstalls (jupyterhub / elastic-stack / minio / starrocks / openobserve) now accept a `PURGE_DATA` Make variable:**

```bash
# SAFE DEFAULT — keeps all PVCs, PVs, and MinIO/S3 bucket data.
make uninstall-jupyterhub          # PURGE_DATA=0 implicitly
make uninstall-openobserve         # keeps PVCs + S3 openobserve bucket

# PURGE — explicitly delete PVCs (and OpenObserve S3 bucket if mc CLI exists):
make uninstall-jupyterhub PURGE_DATA=1
make uninstall-elastic-stack PURGE_DATA=1
make uninstall-openobserve PURGE_DATA=1
```

Semantics (see [cli/common.mk](./cli/common.mk) for exact implementation):

1. **PVC pre-delete pass (only when `PURGE_DATA=1`)**: Lists every PVC in the target namespace and deletes them explicitly, then waits up to `PURGE_WAIT` (default `180`s) for kubelet finalizers and the `local-path` StorageClass' default `reclaimPolicy=Delete` to auto-remove the bound PVs. This prevents 90% of the "dangling orphan PV" problem we see after uninstall.
2. **Namespace delete**: Removes the namespace object itself.
3. **Released-PV garbage collect pass**: Walks **all** cluster PVs and deletes any in phase `Released` or `Failed` whose `.spec.claimRef.namespace` points to the just-deleted namespace. This catches the remaining 10%: CRD operators that patch PV reclaimPolicy to `Retain` (notably ECK, StarRocks operator, some older charts).

For OpenObserve specifically, `PURGE_DATA=1` also deletes the actual S3 bucket (not just PVCs) using the `MC_HOST_<ALIAS>` env-var credential pattern. Credentials are passed via env (never argv/ps):

```bash
# credentials are carried in env vars; argv is just the mc rb command
MC_HOST_LUBAN_MINIO="<MINIO_ROOT_USER>:<MINIO_ROOT_PASSWORD>@minio.<LUBAN_DOMAIN>:9000" \
  mc rb --force luban-minio/openobserve
```

…so the MinIO bucket itself gets wiped, not just OO's metadata/SQLite PVCs. If `mc` isn't installed the step gracefully no-ops and warns.

If you only installed base infrastructure, you can remove it with:

```bash
make uninstall-infra
```

## Troubleshooting

- **Namespace Stuck Terminating**: The uninstall targets attempt to force delete, but if a namespace is stuck, check for lingering finalizers on resources.
- **Gateway Not Ready**: Ensure `cert-manager` is fully installed before installing `gateway`. The `make gateway` target includes a wait check for the cert-manager webhook.
- **Port Conflicts**: Ensure no other gateways (e.g., from other namespaces) are claiming port 443 on the same node IP.
- **Browser Warnings**: This is expected with a self-signed local CA. Follow the "TLS" section above to trust the CA.

## Makefile Notes

Some install targets (notably `infra`) include guards to skip re-install work if the component is already present.
Use `FORCE=1` to explicitly re-apply or upgrade:

```bash
make infra FORCE=1
make observability FORCE=1
```
