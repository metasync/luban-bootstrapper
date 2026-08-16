include ../Makefile.env
include ../cli/common.mk

# JupyterHub installation and Gateway routing configuration.
# Installs JupyterHub using the official Helm chart and configures an HTTPS
# route via Envoy Gateway.

JUPYTERHUB_REPO_URL ?= https://jupyterhub.github.io/helm-chart/

.PHONY: install uninstall

# Purge control (default = 0, keep hub DB and user home PVCs on uninstall)
PURGE_DATA ?= 0

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
		--timeout 10m \
		--wait
	@$(KUBECTL) -n $(JUPYTERHUB_NAMESPACE) patch deployment user-scheduler --type='json' \
		--patch-file user-scheduler-probes.jsonpatch.yaml >/dev/null
	@$(KUBECTL) -n $(JUPYTERHUB_NAMESPACE) rollout status deployment/user-scheduler --timeout=600s
	@echo "Applying Gateway configuration..."
	@export JUPYTERHUB_NAMESPACE=$(JUPYTERHUB_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		JUPYTERHUB_HOST=$(JUPYTERHUB_HOST) \
		JUPYTERHUB_PUBLIC_HOST=$(JUPYTERHUB_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) apply -f -

uninstall:
	@echo "Uninstalling Gateway configuration..."
	@export JUPYTERHUB_NAMESPACE=$(JUPYTERHUB_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		JUPYTERHUB_HOST=$(JUPYTERHUB_HOST) \
		JUPYTERHUB_PUBLIC_HOST=$(JUPYTERHUB_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) delete -f - --ignore-not-found=true || true
	@echo "Uninstalling JupyterHub (Helm release)..."
	@helm uninstall jupyterhub -n $(JUPYTERHUB_NAMESPACE) || true
	$(call purge-namespace,$(JUPYTERHUB_NAMESPACE))
