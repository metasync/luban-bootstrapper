# Keycloak

This component installs the shared Keycloak identity provider for `luban-bootstrapper`.

It is introduced for the Dagster SSO initiative first, but the deployment is intentionally named and scoped so it can be reused by other platform components later.

## Scope

This component currently covers:

- Keycloak installation
- Gateway API exposure
- admin bootstrap secret wiring

This component does not yet cover:

- realm bootstrap
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

## Access

- Local: `https://${KEYCLOAK_HOST}`
- Public: `https://${KEYCLOAK_PUBLIC_HOST}`

## Get The Admin Password

```bash
make -C keycloak get-admin-password
```

## Uninstall

```bash
make uninstall-keycloak
```
