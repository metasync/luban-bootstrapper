include ../Makefile.env
include ../cli/common.mk

.PHONY: install uninstall check

OPENOBSERVE_REPO_URL ?= https://charts.openobserve.ai
OPENOBSERVE_RELEASE_NAME ?= openobserve

# Purge control (default = 0, keep OpenObserve PVCs + MinIO bucket on uninstall)
PURGE_DATA ?= 0

install:
	@if [ ! -f ../secrets/minio.env ]; then \
		echo "Missing ../secrets/minio.env (create it with MINIO_ROOT_USER / MINIO_ROOT_PASSWORD)."; \
		echo "OpenObserve S3 backend uses Luban MinIO (run 'make minio' first if not installed)."; \
		exit 1; \
	fi
	@$(KUBECTL) create namespace $(OPENOBSERVE_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@echo "Loading credentials from ../secrets/*.env ..."
	@set -a; \
	  OO_S3_CREDS_OK=1; \
	  if [ -f ../secrets/openobserve.env ]; then \
	    . ../secrets/openobserve.env; \
	  else \
	    echo "  ../secrets/openobserve.env missing; falling back to defaults (change in production)."; \
	    OO_ROOT_USER_EMAIL=$${OO_ROOT_USER_EMAIL:-root@example.com}; \
	    OO_ROOT_USER_PASSWORD=$${OO_ROOT_USER_PASSWORD:-Complexpass#123}; \
	  fi; \
	  . ../secrets/minio.env; \
	  OO_S3_ENDPOINT=$${OO_S3_ENDPOINT:-http://minio.$(MINIO_NAMESPACE).svc.cluster.local:9000}; \
	  OO_S3_BUCKET=$${OO_S3_BUCKET:-$(OPENOBSERVE_S3_BUCKET_NAME)}; \
	  OO_S3_ENDPOINT_NO_SCHEME=$${OO_S3_ENDPOINT#*://}; \
	  if command -v mc >/dev/null 2>&1; then \
	    echo "Ensuring S3 bucket s3://$$OO_S3_BUCKET exists in MinIO (idempotent via mc mb)..."; \
	    MC_HOST_LUBAN_MINIO="$$MINIO_ROOT_USER:$$MINIO_ROOT_PASSWORD@$$OO_S3_ENDPOINT_NO_SCHEME" \
	      mc mb --ignore-existing luban-minio/$$OO_S3_BUCKET || \
	      echo "  (mc mb returned non-zero; bucket likely already exists or minio unreachable — OpenObserve will attempt auto-create with ZO_LOCAL_MODE=true.)"; \
	  else \
	    echo "mc not found on PATH; skipping bucket pre-create (OpenObserve will try auto-create with ZO_LOCAL_MODE=true)."; \
	  fi; \
	  set +a; \
	  echo "Adding OpenObserve Helm repository..."; \
	  helm repo add openobserve $(OPENOBSERVE_REPO_URL) >/dev/null 2>&1 || true; \
	  helm repo update openobserve >/dev/null; \
	  echo "Installing OpenObserve (Chart v$(OPENOBSERVE_CHART_VERSION), App v$(OPENOBSERVE_APP_VERSION))..."; \
	  set -a; . ../secrets/minio.env; \
	  if [ -f ../secrets/openobserve.env ]; then . ../secrets/openobserve.env; \
	  else OO_ROOT_USER_EMAIL=$${OO_ROOT_USER_EMAIL:-root@example.com}; OO_ROOT_USER_PASSWORD=$${OO_ROOT_USER_PASSWORD:-Complexpass#123}; fi; \
	  OO_S3_ENDPOINT=$${OO_S3_ENDPOINT:-http://minio.$(MINIO_NAMESPACE).svc.cluster.local:9000}; \
	  OO_S3_BUCKET=$${OO_S3_BUCKET:-$(OPENOBSERVE_S3_BUCKET_NAME)}; \
	  set +a; \
	  helm upgrade --install $(OPENOBSERVE_RELEASE_NAME) openobserve/openobserve \
	    --namespace $(OPENOBSERVE_NAMESPACE) \
	    --create-namespace \
	    --version $(OPENOBSERVE_CHART_VERSION) \
	    --values values.yaml \
	    --set auth.ZO_ROOT_USER_EMAIL="$$OO_ROOT_USER_EMAIL" \
	    --set auth.ZO_ROOT_USER_PASSWORD="$$OO_ROOT_USER_PASSWORD" \
	    --set auth.ZO_S3_ACCESS_KEY="$$MINIO_ROOT_USER" \
	    --set auth.ZO_S3_SECRET_KEY="$$MINIO_ROOT_PASSWORD" \
	    --set config.ZO_S3_PROVIDER="s3" \
	    --set config.ZO_S3_SERVER_URL="$$OO_S3_ENDPOINT" \
	    --set config.ZO_S3_REGION_NAME="us-east-1" \
	    --set config.ZO_S3_BUCKET_NAME="$$OO_S3_BUCKET" \
	    --set config.ZO_S3_FEATURE_FORCE_HOSTED_STYLE="false" \
	    --set config.ZO_LOCAL_MODE="true" \
	    --timeout 20m \
	    --wait
	@echo "Applying Gateway configuration for OpenObserve UI... ($(OPENOBSERVE_HOST) / $(OPENOBSERVE_PUBLIC_HOST))"
	@export OPENOBSERVE_NAMESPACE=$(OPENOBSERVE_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		OPENOBSERVE_HOST=$(OPENOBSERVE_HOST) \
		OPENOBSERVE_PUBLIC_HOST=$(OPENOBSERVE_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) apply -f -

check:
	@echo "Checking OpenObserve readiness..."
	@PODS=$$( $(KUBECTL) -n $(OPENOBSERVE_NAMESPACE) get pods --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null ); \
	if [ -z "$$PODS" ]; then echo "No OpenObserve + NATS pods found in namespace $(OPENOBSERVE_NAMESPACE) (not installed yet)"; exit 0; fi; \
	$(KUBECTL) -n $(OPENOBSERVE_NAMESPACE) wait --for=condition=Ready pod \
		--all --timeout=180s
	@echo "UI:        https://$(OPENOBSERVE_HOST)/   (root email: $(OPENOBSERVE_DEFAULT_ROOT_EMAIL))"
	@echo "OTLP HTTP: http://openobserve-router.$(OPENOBSERVE_NAMESPACE).svc.cluster.local:5080/api/default/otlp  (in-cluster, use in luban-config overlays)"
	@echo "OTLP GW:   https://$(OPENOBSERVE_HOST)/api/default/otlp   (SDKs append /v1/{traces,metrics,logs} automatically)"

uninstall:
	@echo "Uninstalling Gateway configuration..."
	@export OPENOBSERVE_NAMESPACE=$(OPENOBSERVE_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		OPENOBSERVE_HOST=$(OPENOBSERVE_HOST) \
		OPENOBSERVE_PUBLIC_HOST=$(OPENOBSERVE_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) delete -f - --ignore-not-found=true || true
	@echo "Uninstalling OpenObserve (Helm release)..."
	@helm uninstall $(OPENOBSERVE_RELEASE_NAME) -n $(OPENOBSERVE_NAMESPACE) || true
	@if [ "$(PURGE_DATA)" = "1" ]; then \
		if [ -f ../secrets/minio.env ] && command -v mc >/dev/null 2>&1; then \
			set -a; . ../secrets/minio.env; set +a; \
			OO_S3_ENDPOINT=$${OO_S3_ENDPOINT:-http://minio.$(MINIO_NAMESPACE).svc.cluster.local:9000}; \
			OO_S3_BUCKET=$${OO_S3_BUCKET:-$(OPENOBSERVE_S3_BUCKET_NAME)}; \
			echo "  [purge] PURGE_DATA=1  -> removing S3 bucket s3://$$OO_S3_BUCKET from MinIO..."; \
			OO_S3_ENDPOINT_NO_SCHEME=$${OO_S3_ENDPOINT#*://}; \
			MC_HOST_LUBAN_MINIO="$$MINIO_ROOT_USER:$$MINIO_ROOT_PASSWORD@$$OO_S3_ENDPOINT_NO_SCHEME" \
				MC_ALIAS_LUBAN_MINIO=luban-minio \
				mc rb --force luban-minio/$$OO_S3_BUCKET >/dev/null 2>&1 || true; \
		else \
			echo "  [purge] PURGE_DATA=1 but no mc or ../secrets/minio.env. Bucket s3://$(OPENOBSERVE_S3_BUCKET_NAME) left as-is (manual cleanup)."; \
		fi; \
	fi
	$(call purge-namespace,$(OPENOBSERVE_NAMESPACE))
