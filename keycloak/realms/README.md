# Keycloak Realms

This directory contains repo-managed realm bootstrap files for the shared Keycloak deployment.

## Current Scope

- `snd.yaml`: sandbox realm with the initial `dagster-access` group, the `snd-dagster-debug` client, and two bootstrap users
- `prd.yaml`: production realm skeleton with the same `groups` claim contract and no production users

## Notes

- These files are applied through the Bitnami chart's `keycloak-config-cli` job.
- The sandbox bootstrap passwords are placeholders for initial validation only.
- Downstream application clients are intentionally not managed here yet.
