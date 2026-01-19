include ../Makefile.env

# cert-manager installation from Helm chart.
# Installs cert-manager with CRDs enabled to support Certificate resources.

JETSTACK_REPO_URL ?= https://charts.jetstack.io

.PHONY: install uninstall

install:
	@echo "Adding Jetstack Helm repository..."
	@helm repo add jetstack $(JETSTACK_REPO_URL)
	@helm repo update jetstack
	@echo "Installing cert-manager (Chart v$(CERT_MANAGER_CHART_VERSION))..."
	# installCRDs=true is required to install the CustomResourceDefinitions
	# (Certificate, Issuer, ClusterIssuer, etc.) alongside the chart.
	@helm upgrade --install cert-manager jetstack/cert-manager \
		--namespace $(CERT_MANAGER_NAMESPACE) \
		--create-namespace \
		--version v$(CERT_MANAGER_CHART_VERSION) \
		--set installCRDs=true \
		--wait

uninstall:
	@echo "Uninstalling cert-manager..."
	@helm uninstall cert-manager -n $(CERT_MANAGER_NAMESPACE)
	@echo "Deleting namespace $(CERT_MANAGER_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(CERT_MANAGER_NAMESPACE) --ignore-not-found=true || true
