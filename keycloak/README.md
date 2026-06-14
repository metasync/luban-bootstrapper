# Keycloak

This component installs the shared Keycloak identity provider for `luban-bootstrapper`.

It is introduced for the Dagster SSO initiative first, but the deployment is intentionally named and scoped so it can be reused by other platform components later.

## Scope

This component currently covers:

- Keycloak installation
- Gateway API exposure
- admin bootstrap secret wiring
- realm bootstrap for `snd` and `prd`

This component does not yet cover:

- LDAP or LDAPS federation
- client bootstrap for downstream applications
- per-platform auth proxy clients

## Install

Option 1: provide the admin password inline:

```bash
make keycloak KEYCLOAK_ADMIN_PASSWORD='<your-password>'
```

Option 2: create `../secrets/keycloak.env`:

```bash
KEYCLOAK_ADMIN_PASSWORD='<your-password>'
```

Then run:

```bash
make keycloak
```

The install flow also applies repo-managed realm bootstrap files through the chart's `keycloak-config-cli` job.

## Access

- Local: `https://${KEYCLOAK_HOST}`
- Public: `https://${KEYCLOAK_PUBLIC_HOST}`

## Bootstrap Realms

- `snd`: includes the initial `dagster-access` group, the `snd-dagster-debug` validation client, and two placeholder users
- `prd`: includes the realm shell and shared `groups` claim contract, but no production users

Realm files live under [realms/](./realms/).

## Get The Admin Password

```bash
make -C keycloak get-admin-password
```

## Uninstall

```bash
make uninstall-keycloak
```
