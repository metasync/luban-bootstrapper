# Luban Kubernetes Tooling

This repository provides Makefile-based tooling to install and manage a
small GitOps and workflow stack on a Kubernetes cluster. It focuses on:

- **Argo Workflows** for workflow orchestration
- **Argo CD** for GitOps application delivery
- **Argo Events** for event-driven workflows
- **kpack** for container image builds
- **Envoy Gateway + Gateway API** for ingress
- **cert-manager** for TLS certificates with a local CA

The setup is tailored for local development on an OrbStack Kubernetes
cluster, using the base domain `k8s.orb.local`.

## Prerequisites

- A Kubernetes cluster (tested with OrbStack)
- `kubectl` configured to point to the cluster
- Internet access to pull manifests from GitHub

You do **not** need to install Envoy Gateway or cert-manager manually;
they are provisioned via the Makefiles.

## Layout

- [Makefile](./Makefile): root orchestration, infra-first install order
- [Makefile.env](./Makefile.env): shared versions and environment variables
- [cert-manager/](./cert-manager/): cert-manager install/uninstall
- [envoy-gateway/](./envoy-gateway/): Envoy Gateway install/uninstall
- [gateway/](./gateway/):
  - [Makefile](./gateway/Makefile): apply/delete gateway resources
  - [resources.yaml](./gateway/resources.yaml): GatewayClass, Gateway, local CA
- [argo-workflows/](./argo-workflows/):
  - [Makefile](./argo-workflows/Makefile): Argo Workflows install/uninstall
  - [gateway.yaml](./argo-workflows/gateway.yaml): Certificate + HTTPRoute
- [argo-cd/](./argo-cd/):
  - [Makefile](./argo-cd/Makefile): Argo CD install/uninstall
  - [gateway.yaml](./argo-cd/gateway.yaml): Certificate + HTTPRoute
- [argo-events/](./argo-events/Makefile): Argo Events install/uninstall
- [kpack/](./kpack/Makefile): kpack install/uninstall

## Configuration

Shared configuration lives in [Makefile.env](./Makefile.env):

- Component versions (Argo, Argo CD, Argo Events, kpack, Envoy Gateway,
  cert-manager)
- Component namespaces
- Base domain and hostnames:
  - `K8S_DOMAIN` (default: `k8s.orb.local`)
  - `ARGO_WORKFLOWS_HOST` (`argo-workflows.${K8S_DOMAIN}`)
  - `ARGO_CD_HOST` (`argocd.${K8S_DOMAIN}`)

The hostnames in `gateway/resources.yaml`, `argo-workflows/gateway.yaml`
and `argo-cd/gateway.yaml` are currently set for `k8s.orb.local`. If you
change `K8S_DOMAIN`, update those YAML files to match.

## Installing the stack

The root [Makefile](./Makefile) installs infrastructure first, followed
by applications.

Install everything:

```bash
make all
```

This runs, in order:

1. `make cert-manager`
2. `make envoy-gateway`
3. `make gateway`
4. `make argo-workflows`
5. `make argo-cd`
6. `make argo-events`
7. `make kpack`

You can also install pieces individually, for example:

```bash
make cert-manager envoy-gateway gateway
make argo-workflows
make argo-cd
```

## Accessing the UIs

After a full install:

- Argo Workflows UI:
  - URL: `https://argo-workflows.k8s.orb.local`
- Argo CD UI:
  - URL: `https://argocd.k8s.orb.local`

TLS is terminated at the `argo-gateway` Gateway. Backend services
(`argo-server`, `argocd-server`) are configured to serve HTTP only.

### Local CA and browser trust

cert-manager issues leaf certificates using a local CA:

- The root CA is defined by the `local-ca` Certificate in the
  `gateway` namespace.
- The corresponding secret is `local-ca-root`.
- The issuer `local-ca-issuer` signs the Argo Workflows and Argo CD
  certificates.

To get rid of browser warnings, you can:

1. Extract the CA certificate from `local-ca-root`:
   - `kubectl get secret local-ca-root -n gateway -o jsonpath='{.data.ca\.crt}' | base64 -D > local-ca.crt`
2. Import `local-ca.crt` into your OS/browser trust store.

## Verification

To verify that Argo Workflows is functioning correctly, you can submit a simple "hello-world" workflow.
The installation configures a default `workflow-runner` service account with necessary permissions, so no extra setup is required.

```bash
# Replace v3.7.7 with your installed Argo Workflows version
kubectl -n argo create -f https://github.com/argoproj/argo-workflows/raw/v3.7.7/examples/hello-world.yaml
```

Check the status of the workflow:

```bash
kubectl -n argo get workflows
```

You should see a workflow with a status of `Succeeded`.

## Uninstalling

To remove everything (applications and infrastructure):

```bash
make uninstall
```

This:

1. Uninstalls Argo Workflows, Argo CD, Argo Events, kpack
2. Removes Gateway resources and local CA
3. Uninstalls Envoy Gateway and cert-manager

You can also call the specific uninstall targets shown by:

```bash
make help
```

## Notes and customization

- To pin different component versions, edit [Makefile.env](./Makefile.env).
- If you change namespaces, make sure:
  - The namespace variables in `Makefile.env` are updated.
  - The namespaces in `argo-workflows/gateway.yaml` and
    `argo-cd/gateway.yaml` match.
- If you change the base domain, update:
  - `K8S_DOMAIN`, `ARGO_WORKFLOWS_HOST`, `ARGO_CD_HOST` in
    [Makefile.env](./Makefile.env)
  - The `hostname` and `hostnames` fields in:
    - [gateway/resources.yaml](./gateway/resources.yaml)
    - [argo-workflows/gateway.yaml](./argo-workflows/gateway.yaml)
    - [argo-cd/gateway.yaml](./argo-cd/gateway.yaml)

