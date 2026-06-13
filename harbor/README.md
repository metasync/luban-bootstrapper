# Harbor

This component installs Harbor and exposes the UI through the shared Envoy Gateway.

## Scope

This component currently covers:

- Harbor Helm installation
- gateway exposure
- built-in persistence
- post-install probe patching for Harbor workloads

This component does not cover:

- external database or Redis integration
- external object storage configuration
- SSO integration

## Install

From the project root:

```bash
make harbor
```

Or from this directory:

```bash
make install
```

## Access

- Local: `https://${HARBOR_HOST}`
- Public: `https://${HARBOR_PUBLIC_HOST}`

## Authentication

Retrieve the admin password:

```bash
make -C harbor get-password
```

## Notes

- TLS is terminated at the shared gateway, so Harbor is installed with `expose.type=clusterIP` and `expose.tls.enabled=false`.
- The install patches readiness and liveness probes for multiple Harbor components after Helm deployment.
- The public URL for Harbor is currently set from `HARBOR_HOST` during install. If public-host canonical behavior matters later, that is worth revisiting separately.

## Verification

```bash
kubectl -n ${HARBOR_NAMESPACE} get pods,svc,secrets
kubectl -n ${HARBOR_NAMESPACE} get httproute
```

## Uninstall

```bash
make uninstall-harbor
```
