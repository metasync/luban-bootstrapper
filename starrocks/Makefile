include ../Makefile.env
include ../cli/common.mk

.PHONY: install uninstall check-minio

check-minio:
	@$(MAKE) -C ../minio check

# Purge control (default = 0, keep StarRocks FE/BE/CN PVCs and data on uninstall)
PURGE_DATA ?= 0

install: check-minio
	@if [ ! -f ../secrets/minio.env ]; then echo "Missing ../secrets/minio.env (create it with MINIO_ROOT_USER and MINIO_ROOT_PASSWORD)"; exit 1; fi
	@echo "Adding StarRocks Helm repository..."
	@helm repo add starrocks https://starrocks.github.io/starrocks-kubernetes-operator
	@helm repo update starrocks
	@echo "Installing StarRocks Operator & Cluster (Chart v$(STARROCKS_CHART_VERSION))..."
	@TMP_VALUES=$$(mktemp /tmp/starrocks-values.XXXXXX.yaml); \
	set -a; . ../secrets/minio.env; set +a; \
	envsubst < values.yaml > $$TMP_VALUES; \
	helm upgrade --install starrocks starrocks/kube-starrocks \
		--namespace $(STARROCKS_NAMESPACE) \
		--create-namespace \
		--version $(STARROCKS_CHART_VERSION) \
		--values $$TMP_VALUES \
		--wait; \
	rm -f $$TMP_VALUES
	@$(KUBECTL) -n $(STARROCKS_NAMESPACE) patch deployment kube-starrocks-operator --type='json' \
		--patch-file operator-probes.jsonpatch.yaml >/dev/null
	@$(KUBECTL) -n $(STARROCKS_NAMESPACE) rollout status deployment/kube-starrocks-operator --timeout=600s
	@echo "Applying Gateway configuration for StarRocks HTTP..."
	@export STARROCKS_NAMESPACE=$(STARROCKS_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		STARROCKS_HOST=$(STARROCKS_HOST) \
		STARROCKS_PUBLIC_HOST=$(STARROCKS_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) apply -f -

uninstall:
	@echo "Uninstalling Gateway configuration..."
	@export STARROCKS_NAMESPACE=$(STARROCKS_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		STARROCKS_HOST=$(STARROCKS_HOST) \
		STARROCKS_PUBLIC_HOST=$(STARROCKS_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) delete -f - --ignore-not-found=true || true
	@echo "Uninstalling StarRocks..."
	@helm uninstall starrocks -n $(STARROCKS_NAMESPACE) || true
	$(call purge-namespace,$(STARROCKS_NAMESPACE))
