include ../Makefile.env

# Envoy Gateway installation using the upstream install manifest.

ENVOY_GATEWAY_INSTALL_URL ?= https://github.com/envoyproxy/gateway/releases/download/v$(ENVOY_GATEWAY_VERSION)/install.yaml

.PHONY: install uninstall

install:
	@echo "Installing Envoy Gateway v$(ENVOY_GATEWAY_VERSION)..."
	@$(KUBECTL) apply --server-side -f $(ENVOY_GATEWAY_INSTALL_URL)
	@echo "Waiting for Envoy Gateway to be ready..."
	@$(KUBECTL) wait -n $(ENVOY_GATEWAY_NAMESPACE) deployment/envoy-gateway --for=condition=Available --timeout=5m

uninstall:
	@echo "Uninstalling Envoy Gateway..."
	@$(KUBECTL) delete --server-side -f $(ENVOY_GATEWAY_INSTALL_URL) || true
	@echo "Deleting namespace $(ENVOY_GATEWAY_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(ENVOY_GATEWAY_NAMESPACE) --ignore-not-found=true || true
