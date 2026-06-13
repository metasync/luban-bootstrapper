# Gateway

This component installs the shared Gateway API resources for `luban-bootstrapper`.

It provides:

- the `gateway` namespace
- the `envoy` `GatewayClass`
- the shared `luban-gateway`
- local wildcard TLS via a local CA
- public wildcard TLS via `cert-manager` and Cloudflare DNS

## Scope

This component currently covers:

- shared `GatewayClass` and `Gateway` resources
- local wildcard certificates for `*.${K8S_DOMAIN}` and `*.${APPS_DOMAIN}`
- public wildcard certificates for `*.${LUBAN_PUBLIC_DOMAIN}` and `*.${APPS_PUBLIC_DOMAIN}`
- optional Cloudflare API token secret wiring

This component does not cover:

- application-specific `HTTPRoute` resources
- per-service authentication
- DNS ownership outside the configured domains

## Prerequisites

- `cert-manager` must already be installed
- `envoy-gateway` must already be installed
- for public certificates, create `../secrets/cloudflare.env` with:

```bash
CLOUDFLARE_API_TOKEN='<your-token>'
```

## Install

From the project root:

```bash
make gateway
```

Or from this directory:

```bash
make install
```

To force re-application:

```bash
make gateway FORCE=1
```

## Verification

Check the shared gateway:

```bash
kubectl -n gateway get gateway,gatewayclass
kubectl -n gateway get certificate,issuer,clusterissuer
```

Export the local CA certificate:

```bash
make -C gateway get-local-ca-crt
```

## Notes

- This component creates the shared listeners used by other services.
- Local application routes typically bind to `*.${APPS_DOMAIN}`.
- Public application routes typically bind to `*.${APPS_PUBLIC_DOMAIN}`.

## Uninstall

```bash
make uninstall-gateway
```
