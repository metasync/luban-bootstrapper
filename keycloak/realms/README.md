# Keycloak Realms

This directory contains repo-managed realm bootstrap files for the shared Keycloak deployment.

## Current Scope

- `snd.yaml`: `KeycloakRealmImport` for the sandbox realm with the initial `dagster-access` group, the `snd-dagster-debug` and `snd-dagster-gateway` clients, and two bootstrap users
- `prd.yaml`: `KeycloakRealmImport` for the production realm skeleton with the same `groups` claim contract, the `prd-dagster-gateway` client, and no production users

## Notes

- These files are applied through the upstream Keycloak Operator as `KeycloakRealmImport` resources.
- Realm imports are create-only. If a realm already exists, later changes here are not reconciled back into Keycloak.
- The sandbox bootstrap passwords are placeholders for initial validation only.
- Downstream application clients beyond the shared gateway bootstrap clients are intentionally not managed here yet.
