include ../Makefile.env

# Envoy Gateway installation from helm chart
# Installs Envoy Gateway using the official OCI Helm chart.

ENVOY_GATEWAY_CHART_URL ?= oci://docker.io/envoyproxy/gateway-helm

.PHONY: install uninstall

install:
	@if [ "$(FORCE)" != "1" ] && helm status eg -n $(ENVOY_GATEWAY_NAMESPACE) >/dev/null 2>&1; then \
		echo "envoy-gateway already installed (set FORCE=1 to upgrade)"; \
	else \
		echo "=== Installing Envoy Gateway ==="; \
		helm upgrade --install eg $(ENVOY_GATEWAY_CHART_URL) \
			--version v$(ENVOY_GATEWAY_CHART_VERSION) \
			--namespace $(ENVOY_GATEWAY_NAMESPACE) \
			--create-namespace \
			--values values.yaml \
			--wait; \
	fi

uninstall:
	@echo "=== Uninstalling Envoy Gateway ==="
	@helm uninstall eg --namespace $(ENVOY_GATEWAY_NAMESPACE) || true
	@echo "Deleting namespace $(ENVOY_GATEWAY_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(ENVOY_GATEWAY_NAMESPACE) --ignore-not-found=true || true
