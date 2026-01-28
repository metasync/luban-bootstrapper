# Luban Kubernetes Bootstrapper for CI/CD Tools

This repository provides Makefile-based tooling to install and manage a comprehensive GitOps and workflow stack on a Kubernetes cluster. It is optimized for local development using **OrbStack** on macOS, but can be adapted for other environments.

The stack includes:

- **Argo Workflows** (Workflow orchestration)
- **Argo CD** (GitOps application delivery)
- **Argo Events** (Event-driven dependency manager)
- **Harbor** (Container Registry)
- **kpack** (Cloud Native Buildpacks for Kubernetes)
- **Envoy Gateway + Gateway API** (Modern Ingress and Traffic Management)
- **cert-manager** (TLS certificate management with a local CA)

## Prerequisites

- **macOS** (Optimized for `base64 -D` and OrbStack domains)
- **Kubernetes Cluster** (Tested with [OrbStack](https://orbstack.dev/))
- **Internet Access** (To pull Helm charts and container images)

The following CLI tools can be installed automatically via `make cli`:
- `kubectl`
- `helm`
- `pack`
- `kp`

## Layout

- **[Makefile](./Makefile)**: Root orchestration. Installs infrastructure first, then applications.
- **[Makefile.env](./Makefile.env)**: Shared configuration (versions, namespaces, domains).
- **[cli/](./cli/)**: CLI installation logic (pack, kp, helm, kubectl).
- **[argo-workflows/](./argo-workflows/)**: Argo Workflows Helm install & Gateway config.
- **[argo-cd/](./argo-cd/)**: Argo CD Helm install & Gateway config.
- **[argo-events/](./argo-events/)**: Argo Events Helm install.
- **[harbor/](./harbor/)**: Harbor Helm install & Gateway config.
- **[cert-manager/](./cert-manager/)**: cert-manager Helm install.
- **[envoy-gateway/](./envoy-gateway/)**: Envoy Gateway Helm OCI install.
- **[gateway/](./gateway/)**: Gateway API resources (GatewayClass, Gateway, Local CA).
- **[kpack/](./kpack/)**: kpack raw manifest install.

## Configuration

Shared configuration lives in [Makefile.env](./Makefile.env). You can customize:

- **Component Versions**:
  - Argo Workflows (App v3.7.7)
  - Argo CD (App v3.2.5)
  - Argo Events (App v1.9.9)
  - Harbor (App v2.14.0)
  - kpack (v0.17.1)
  - Envoy Gateway (v1.6.2)
  - cert-manager (v1.19.2)
- **CLI Versions**:
  - Helm (v4.0.5)
  - Kubectl (v1.35.0)
  - Pack (v0.39.1)
  - kp (v0.13.1)
- **Namespaces**: Define where each component is installed.
- **Domains**:
  - `K8S_DOMAIN` (default: `k8s.orb.local`)
  - `ARGO_WORKFLOWS_HOST` (`argo-workflows.k8s.orb.local`)
  - `ARGO_CD_HOST` (`argocd.k8s.orb.local`)
  - `HARBOR_HOST` (`harbor.k8s.orb.local`)

## Installation

### 1. Install CLIs

Ensure you have the necessary tools installed:

```bash
make cli
```
Or install them individually: `make helm-cli`, `make kubectl-cli`, `make pack-cli`, `make kp-cli`.

### 2. Install the Stack

To install infrastructure (Cert Manager, Envoy Gateway) and all applications:

```bash
make all
```

Or install components individually:

```bash
make cert-manager envoy-gateway gateway
make argo-workflows
make argo-cd
make harbor
```

## Accessing the UIs

The stack uses Envoy Gateway to expose UIs via HTTPS. The gateway (`luban-gateway`) supports wildcard subdomains on `*.luban.k8s.orb.local` as well as legacy `*.k8s.orb.local` domains.

| Component | URL | Notes |
|-----------|-----|-------|
| **Argo Workflows** | `https://argo-workflows.k8s.orb.local` | Requires Token |
| **Argo CD** | `https://argocd.k8s.orb.local` | User: `admin` |
| **Harbor** | `https://harbor.k8s.orb.local` | User: `admin` |

New services can be exposed by binding an `HTTPRoute` to the `luban-ci` listener on `luban-gateway` with a `*.luban.k8s.orb.local` hostname.

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
make -C argo-cd get-password
```

**Harbor:**
To retrieve the initial `admin` password:

```bash
make -C harbor get-password
```

### DNS & TLS

- **DNS**: OrbStack automatically resolves `*.k8s.orb.local` to your cluster's LoadBalancer. If not using OrbStack, add entries to `/etc/hosts`.
- **TLS**: A local CA is generated in the `gateway` namespace.
  - To trust the CA, extract the certificate:
    ```bash
    kubectl get secret local-ca-root -n gateway -o jsonpath='{.data.ca\.crt}' | base64 -D > local-ca.crt
    ```
  - Import `local-ca.crt` into your Keychain / Browser trust store.
  - Certificate rotation policy:
    - Leaf certs (Argocd/Workflows): duration `2160h` (90d), renewBefore `360h` (15d)
    - Local CA: duration `43800h` (5y), renewBefore `720h` (30d)
    - Values use Go `time.Duration` format (h/m/s), not `d`.

## Verification

**Argo Workflows:**
Submit a "Hello World" workflow:

```bash
# Submit a workflow using the installed version examples
kubectl -n argo create -f https://github.com/argoproj/argo-workflows/raw/v3.7.7/examples/hello-world.yaml

# Check status
kubectl -n argo get workflows
```

**Argo CD:**
Login to the UI and check that the status is "Healthy".

**Harbor:**
Login to the UI and create a new project.

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
