include ../Makefile.env

# cert-manager installation from the specified release manifest.

CERT_MANAGER_MANIFEST_URL ?= https://github.com/cert-manager/cert-manager/releases/download/v$(CERT_MANAGER_VERSION)/cert-manager.yaml

.PHONY: install uninstall

install:
	@echo "Installing cert-manager v$(CERT_MANAGER_VERSION)..."
	@$(KUBECTL) apply -f $(CERT_MANAGER_MANIFEST_URL)
	@echo "Waiting for cert-manager deployments to be ready..."
	@$(KUBECTL) wait -n $(CERT_MANAGER_NAMESPACE) deployment/cert-manager --for=condition=Available --timeout=5m
	@$(KUBECTL) wait -n $(CERT_MANAGER_NAMESPACE) deployment/cert-manager-cainjector --for=condition=Available --timeout=5m
	@$(KUBECTL) wait -n $(CERT_MANAGER_NAMESPACE) deployment/cert-manager-webhook --for=condition=Available --timeout=5m

uninstall:
	@echo "Uninstalling cert-manager..."
	@$(KUBECTL) delete -f $(CERT_MANAGER_MANIFEST_URL) || true
	@echo "Deleting namespace $(CERT_MANAGER_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(CERT_MANAGER_NAMESPACE) --ignore-not-found=true || true
