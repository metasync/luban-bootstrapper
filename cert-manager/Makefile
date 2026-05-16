include ../Makefile.env

# cert-manager installation from Helm chart.
# Installs cert-manager with CRDs enabled to support Certificate resources.

JETSTACK_REPO_URL ?= https://charts.jetstack.io

.PHONY: install uninstall

install:
	@if [ "$(FORCE)" != "1" ] && helm status cert-manager -n $(CERT_MANAGER_NAMESPACE) >/dev/null 2>&1; then \
		echo "cert-manager already installed (set FORCE=1 to upgrade)"; \
	else \
		echo "Adding Jetstack Helm repository..."; \
		helm repo add jetstack $(JETSTACK_REPO_URL); \
		helm repo update jetstack; \
		echo "Installing cert-manager (Chart v$(CERT_MANAGER_CHART_VERSION))..."; \
		helm upgrade --install cert-manager jetstack/cert-manager \
			--namespace $(CERT_MANAGER_NAMESPACE) \
			--create-namespace \
			--version v$(CERT_MANAGER_CHART_VERSION) \
			--values values.yaml \
			--set crds.enabled=true \
			--set extraArgs="{--dns01-recursive-nameservers=8.8.8.8:53,--dns01-recursive-nameservers-only=true}" \
			--timeout 10m \
			--wait; \
	fi

uninstall:
	@echo "Uninstalling cert-manager..."
	@helm uninstall cert-manager -n $(CERT_MANAGER_NAMESPACE) || true
	@echo "Deleting namespace $(CERT_MANAGER_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(CERT_MANAGER_NAMESPACE) --ignore-not-found=true || true
