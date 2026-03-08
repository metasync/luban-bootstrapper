include ../Makefile.env

# JupyterHub installation and Gateway routing configuration.
# Installs JupyterHub using the official Helm chart and configures an HTTPS
# route via Envoy Gateway.

JUPYTERHUB_REPO_URL ?= https://jupyterhub.github.io/helm-chart/

.PHONY: install uninstall

install:
	@echo "Adding JupyterHub Helm repository..."
	@helm repo add jupyterhub $(JUPYTERHUB_REPO_URL)
	@helm repo update jupyterhub
	@echo "Installing JupyterHub (Chart v$(JUPYTERHUB_CHART_VERSION))..."
	@helm upgrade --install jupyterhub jupyterhub/jupyterhub \
		--namespace $(JUPYTERHUB_NAMESPACE) \
		--create-namespace \
		--version $(JUPYTERHUB_CHART_VERSION) \
		--values values.yaml \
		--set proxy.service.type=ClusterIP \
		--set proxy.https.enabled=false \
		--set ingress.enabled=false \
		--wait
	@echo "Applying Gateway configuration..."
	@$(KUBECTL) apply -f gateway.yaml

uninstall:
	@echo "Uninstalling Gateway configuration..."
	@$(KUBECTL) delete -f gateway.yaml --ignore-not-found=true || true
	@echo "Uninstalling JupyterHub..."
	@helm uninstall jupyterhub -n $(JUPYTERHUB_NAMESPACE) || true
	@echo "Deleting namespace $(JUPYTERHUB_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(JUPYTERHUB_NAMESPACE) --ignore-not-found=true || true
