# Keycloak

This component installs the shared Keycloak identity provider for `luban-bootstrapper`.

It now uses the upstream Keycloak Operator plus the official Keycloak container image instead of the Bitnami chart. The component remains intentionally named and scoped so it can be reused by platform services beyond Dagster.

## Scope

This component currently covers:

- upstream Keycloak Operator installation
- official Keycloak deployment via a `Keycloak` custom resource
- repo-managed PostgreSQL for local and bootstrap environments
- Gateway API exposure on `idp.*`
- bootstrap admin secret wiring
- realm bootstrap for `snd` and `prd`

This component does not yet cover:

- a custom optimized Keycloak image build pipeline
- LDAP or LDAPS federation
- ongoing declarative updates to existing realms after initial import
- arbitrary client bootstrap for downstream applications beyond the shared gateway clients
- per-platform auth proxy clients

## Install

Preferred: create `../secrets/keycloak.env`:

```bash
KEYCLOAK_ADMIN_PASSWORD='<your-password>'
# Optional: set this if you do not want the Makefile to generate one
KEYCLOAK_DB_PASSWORD='<your-db-password>'
```

That file is local-only and git-ignored, like the other secret env files under `secrets/`.

Then run:

```bash
make keycloak
```

Alternative: provide the admin password inline:

```bash
make keycloak KEYCLOAK_ADMIN_PASSWORD='<your-password>'
```

The install flow performs these steps:

- installs the upstream Keycloak Operator and CRDs
- applies the database secret
- applies the repo-managed PostgreSQL `Service` from `postgresql-service.yaml`
- creates the repo-managed PostgreSQL `StatefulSet` from `postgresql-statefulset.yaml`
- applies the bootstrap admin secret
- deploys Keycloak through `keycloak.yaml`
- applies repo-managed `KeycloakRealmImport` resources for `snd` and `prd`

## Access

- Local: `https://${KEYCLOAK_HOST}`
- Public: `https://${KEYCLOAK_PUBLIC_HOST}`

Keycloak now uses `KEYCLOAK_CANONICAL_HOST` as its advertised OIDC hostname, which defaults to the public URL. The local `idp.*` route still works for cluster access, but discovery documents and browser redirects stay pinned to the canonical public host.

## Bootstrap Realms

- `snd`: includes the initial `dagster-access` group, the `snd-dagster-debug` validation client, the `snd-dagster-gateway` client, and two placeholder users
- `prd`: includes the realm shell, the shared `groups` claim contract, the `prd-dagster-gateway` client, and no production users

The gateway clients stay environment-level even when `luban-ci` provisions project-specific gateway hosts. `luban-bootstrapper` now boots those shared clients with the baseline claim contract only and leaves redirect/origin/logout URL lists empty. `luban-ci` fills in exact gateway hosts later during gateway provisioning because released Keycloak versions do not honor wildcard subdomain redirects for OIDC clients.

Current sandbox bootstrap users:

- `alice.dagster` / `change-me-snd-alice`
- `blocked.dagster` / `change-me-snd-blocked`

Realm import files live under [realms/](./realms/).

## Notes

- The Operator watches the same namespace as the Keycloak instance by default.
- `KeycloakRealmImport` is create-only; it does not reconcile later edits back into an existing realm.
- Because of that create-only behavior, newly added clients become fully declarative only on a fresh realm import or reinstall. Existing realms may need a one-time manual client creation when the client is introduced after the initial import.
- Dagster Gateway bootstrap clients intentionally start with empty redirect/origin/logout URL lists. Exact gateway hosts are added later by `luban-ci` when those gateways are provisioned.
- The PostgreSQL manifests here are intended for bootstrap and local cluster usage, not as the final production database architecture.
- Re-running install reapplies both the PostgreSQL `Service` and `StatefulSet`, so mutable settings such as image, probes, and resources stay aligned with the repo.
- If you change immutable PostgreSQL storage fields later, Kubernetes will reject the re-apply and you will need an explicit database migration or reinstall path.
- `make uninstall-keycloak` removes the namespace-scoped Keycloak resources and bootstrap PostgreSQL state only. The operator and CRDs are left intact so other namespaces or future installs are not disrupted. Use `make -C keycloak full-uninstall` only when you intentionally want to remove the shared operator stack from the cluster.

## Get The Admin Password

```bash
make -C keycloak get-admin-password
```

## Uninstall

```bash
make uninstall-keycloak
```
