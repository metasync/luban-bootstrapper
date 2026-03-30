# Luban Kubernetes Bootstrapper for CI/CD Tools

This repository provides Makefile-based tooling to install and manage a comprehensive GitOps and workflow stack on a Kubernetes cluster. It is optimized for local development using **OrbStack** on macOS, but can be adapted for other environments.

The stack includes:

- **Core CI/CD stack (installed via `make all`)**
  - **Argo Workflows** (Workflow orchestration)
  - **Argo CD** (GitOps application delivery)
  - **Argo Events** (Event-driven dependency manager)
  - **Harbor** (Container Registry)
  - **kpack** (Cloud Native Buildpacks for Kubernetes)
  - **Kubernetes Replicator** (Secret/ConfigMap replication)
  - **Envoy Gateway + Gateway API** (Modern Ingress and Traffic Management)
  - **cert-manager** (TLS certificate management with a local CA)

- **Optional stack components (installed separately)**
  - **JupyterHub** (Multi-user Notebook Platform)
  - **MinIO** (S3-compatible object storage)
  - **StarRocks (shared-data)** (High-performance Analytical Database; requires MinIO)

## Prerequisites

- **macOS** (Optimized for `base64 -D` and OrbStack domains)
- **Kubernetes Cluster** (Tested with [OrbStack](https://orbstack.dev/))
- **Internet Access** (To pull Helm charts and container images)
- `envsubst` (used to render Gateway/HTTPRoute templates; comes with `gettext`)

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

### Core CI/CD stack (`make all`)

- **[argo-workflows/](./argo-workflows/)**: Argo Workflows Helm install & Gateway config.
- **[argo-cd/](./argo-cd/)**: Argo CD Helm install & Gateway config.
- **[argo-events/](./argo-events/)**: Argo Events Helm install.
- **[harbor/](./harbor/)**: Harbor Helm install & Gateway config.
- **[cert-manager/](./cert-manager/)**: cert-manager Helm install.
- **[kubernetes-replicator/](./kubernetes-replicator/)**: Kubernetes Replicator Helm install.
- **[envoy-gateway/](./envoy-gateway/)**: Envoy Gateway Helm OCI install.
- **[gateway/](./gateway/)**: Gateway API resources (GatewayClass, Gateway, Local CA).
- **[kpack/](./kpack/)**: kpack raw manifest install.

### Optional components

- **[jupyterhub/](./jupyterhub/)**: JupyterHub Helm install & Gateway config.
- **[minio/](./minio/)**: MinIO Helm install & Gateway config.
- **[starrocks/](./starrocks/)**: StarRocks Operator Helm install (shared-data; requires MinIO).

## Configuration

Shared configuration lives in [Makefile.env](./Makefile.env). You can customize:

- **Component Versions**:
  - Argo Workflows (App v4.0.3)
  - Argo CD (App v3.3.6)
  - Argo Events (App v1.9.10)
  - Harbor (App v2.14.0)
  - JupyterHub (App v5.4.3)
  - MinIO (RELEASE.2024-12-18T13-15-44Z)
  - StarRocks Operator (App v1.11.4)
  - kpack (v0.17.1)
  - Kubernetes Replicator (v2.12.3)
  - Envoy Gateway (v1.6.2)
  - cert-manager (v1.19.2)
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

1. Create a file `secrets/minio.env` (this file is git-ignored).
2. Add the required keys:
   ```bash
   MINIO_ROOT_USER=your-minio-user
   MINIO_ROOT_PASSWORD=your-minio-password
   ```
3. Install MinIO first, then StarRocks:
   ```bash
   make minio
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

To install core infrastructure and all default CI/CD components:

```bash
make all
```

### 4. Install optional components

```bash
make jupyterhub
make minio
make starrocks
```

## Accessing the UIs

The stack uses Envoy Gateway to expose UIs via HTTPS. The gateway (`luban-gateway`) supports wildcard subdomains for both local development and public access.

| Component | Local URL | Public URL | Notes |
|-----------|-----------|------------|-------|
| **Argo Workflows** | `https://argo-workflows.<K8S_DOMAIN>` | `https://argo-workflows.<LUBAN_PUBLIC_DOMAIN>` | Requires Token |
| **Argo CD** | `https://argocd.<K8S_DOMAIN>` | `https://argocd.<LUBAN_PUBLIC_DOMAIN>` | User: `admin` |
| **Harbor** | `https://harbor.<K8S_DOMAIN>` | `https://harbor.<LUBAN_PUBLIC_DOMAIN>` | User: `admin` |
| **JupyterHub** | `https://jupyterhub.<K8S_DOMAIN>` | `https://jupyterhub.<LUBAN_PUBLIC_DOMAIN>` | Any User |
| **MinIO Console** | `https://minio-console.<K8S_DOMAIN>` | `https://minio-console.<LUBAN_PUBLIC_DOMAIN>` | User: `MINIO_ROOT_USER` |
| **StarRocks FE** | `https://starrocks.<K8S_DOMAIN>` | `https://starrocks.<LUBAN_PUBLIC_DOMAIN>` | User: `root` (empty password) |

New services can be exposed by binding an `HTTPRoute` to the `luban-local` listener on `luban-gateway` with a `*.<K8S_DOMAIN>` hostname (or `luban-public` for `*.<LUBAN_PUBLIC_DOMAIN>`).

Applications can be exposed using the `*.<APPS_DOMAIN>` (local) or `*.<APPS_PUBLIC_DOMAIN>` (public) wildcard domains.

### Authentication

**Argo Workflows:**
The installation generates a `workflow-runner` service account and a token secret. To retrieve the token for login:

```bash
make -C argo-workflows get-token
```
Copy the output and paste it into the UI login prompt.

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
      kubectl get secret local-ca-root -n gateway -o jsonpath='{.data.ca\.crt}' | base64 -D > local-ca.crt
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
kubectl -n argo create -f https://github.com/argoproj/argo-workflows/raw/v4.0.3/examples/hello-world.yaml

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
make uninstall
```

This target ensures a clean slate by removing namespaces (`argo`, `argocd`, `envoy-gateway-system`, etc.) to prevent issues with lingering resources.

## Troubleshooting

- **Namespace Stuck Terminating**: The uninstall targets attempt to force delete, but if a namespace is stuck, check for lingering finalizers on resources.
- **Gateway Not Ready**: Ensure `cert-manager` is fully installed before installing `gateway`. The `make gateway` target includes a wait check for the cert-manager webhook.
- **Port Conflicts**: Ensure no other gateways (e.g., from other namespaces) are claiming port 443 on the same node IP.
- **Browser Warnings**: This is expected with a self-signed local CA. Follow the "TLS" section above to trust the CA.
