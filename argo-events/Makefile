include ../Makefile.env

# Argo Events installation for the configured namespace.
# Installs Argo Events using the official Helm chart to support event-driven workflows.

ARGO_REPO_URL ?= https://argoproj.github.io/argo-helm

.PHONY: install uninstall

install:
	@echo "Adding Argo Helm repository..."
	@helm repo add argo $(ARGO_REPO_URL)
	@helm repo update argo
	@echo "Installing Argo Events (Chart v$(ARGO_EVENTS_CHART_VERSION))..."
	@helm upgrade --install argo-events argo/argo-events \
		--namespace $(ARGO_EVENTS_NAMESPACE) \
		--create-namespace \
		--version $(ARGO_EVENTS_CHART_VERSION) \
		--set controller.readinessProbe.timeoutSeconds=5 \
		--set controller.readinessProbe.failureThreshold=6 \
		--set controller.livenessProbe.timeoutSeconds=5 \
		--set controller.livenessProbe.failureThreshold=6 \
		--set webhook.readinessProbe.timeoutSeconds=5 \
		--set webhook.readinessProbe.failureThreshold=6 \
		--set webhook.livenessProbe.timeoutSeconds=5 \
		--set webhook.livenessProbe.failureThreshold=6 \
		--timeout 10m \
		--wait

uninstall:
	@echo "Uninstalling Argo Events..."
	@helm uninstall argo-events -n $(ARGO_EVENTS_NAMESPACE) || true
	@echo "Deleting namespace $(ARGO_EVENTS_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(ARGO_EVENTS_NAMESPACE) --ignore-not-found=true || true
