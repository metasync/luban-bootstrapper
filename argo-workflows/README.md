# Argo Workflows

This component installs Argo Workflows and exposes the UI through the shared Envoy Gateway.

## Scope

This component currently covers:

- Argo Workflows Helm installation
- workflow runner RBAC bootstrap
- gateway exposure for the UI
- a gateway timeout policy
- token generation for UI access

This component does not cover:

- SSO integration
- workflow template libraries
- per-team namespace segmentation

## Install

From the project root:

```bash
make argo-workflows
```

Or from this directory:

```bash
make install
```

## Access

- Local: `https://${ARGO_WORKFLOWS_HOST}`
- Public: `https://${ARGO_WORKFLOWS_PUBLIC_HOST}`

## Authentication

Retrieve the standard UI token:

```bash
make -C argo-workflows get-token
```

Generate a temporary cluster-admin bearer token:

```bash
make -C argo-workflows admin-token
```

## Notes

- TLS is terminated at the shared gateway, so the Argo server runs with `server.secure=false`.
- The install patches the server probes after Helm deployment.
- The default workflow service account is `workflow-runner`.

## Verification

```bash
kubectl -n ${ARGO_WORKFLOWS_NAMESPACE} get pods,svc,secrets
kubectl -n ${ARGO_WORKFLOWS_NAMESPACE} get httproute
```

## Uninstall

```bash
make uninstall-argo-workflows
```
