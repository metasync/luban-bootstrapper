# Elastic Stack

This component installs Elasticsearch and Kibana on Kubernetes through the Elastic Cloud on Kubernetes operator.

It also supports an optional Fleet-managed APM setup.

## Scope

This component currently covers:

- ECK operator installation
- Elasticsearch and Kibana installation
- gateway exposure for Kibana
- optional Fleet Server, Elastic Agent, and APM gateway exposure
- Kibana encryption key bootstrap

This component does not cover:

- snapshot repository setup
- external identity provider integration
- custom index lifecycle management

## Install

Install Elasticsearch and Kibana only:

```bash
make elastic-stack-core
```

Install Elasticsearch, Kibana, and Fleet-managed APM:

```bash
make elastic-stack
```

Or from this directory:

```bash
make install
make install-fleet-apm
```

## Access

- Kibana local: `https://${KIBANA_HOST}`
- Kibana public: `https://${KIBANA_PUBLIC_HOST}`
- APM local: `https://${APM_HOST}`
- APM public: `https://${APM_PUBLIC_HOST}`

## Authentication

Retrieve the `elastic` user password:

```bash
make -C elastic-stack get-elastic-password
```

## Notes

- This component manages two namespaces:
  - `$(ELASTIC_SYSTEM_NAMESPACE)` for the ECK operator
  - `$(ELASTIC_STACK_NAMESPACE)` for Elasticsearch, Kibana, and Fleet resources
- Kibana encryption keys are created automatically if the secret does not already exist.
- `make elastic-stack-core` installs only Elasticsearch and Kibana.
- `make elastic-stack` adds Fleet Server, Elastic Agent, and APM exposure on top of the core stack.

## Verification

```bash
kubectl -n ${ELASTIC_SYSTEM_NAMESPACE} get pods
kubectl -n ${ELASTIC_STACK_NAMESPACE} get elasticsearch,kibana,agent
kubectl -n ${ELASTIC_STACK_NAMESPACE} get httproute,secrets
```

## Uninstall

Remove the full stack:

```bash
make uninstall-elastic-stack
```
