include ../Makefile.env

# Argo Events installation for the configured namespace.

ARGO_EVENTS_BASE_URL ?= https://github.com/argoproj/argo-events/releases/download/v$(ARGO_EVENTS_VERSION)

.PHONY: install uninstall

install:
	@echo "Creating namespace $(ARGO_EVENTS_NAMESPACE)..."
	@$(KUBECTL) create namespace $(ARGO_EVENTS_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@echo "Installing Argo Events v$(ARGO_EVENTS_VERSION)..."
	@$(KUBECTL) apply -n $(ARGO_EVENTS_NAMESPACE) -f $(ARGO_EVENTS_BASE_URL)/install.yaml
	@$(KUBECTL) apply -n $(ARGO_EVENTS_NAMESPACE) -f $(ARGO_EVENTS_BASE_URL)/install-validating-webhook.yaml
	@echo "Waiting for Argo Events Controller to be ready..."
	@$(KUBECTL) wait -n $(ARGO_EVENTS_NAMESPACE) deployment/controller-manager --for=condition=Available --timeout=5m

uninstall:
	@echo "Uninstalling Argo Events..."
	@$(KUBECTL) delete -n $(ARGO_EVENTS_NAMESPACE) -f $(ARGO_EVENTS_BASE_URL)/install-validating-webhook.yaml || true
	@$(KUBECTL) delete -n $(ARGO_EVENTS_NAMESPACE) -f $(ARGO_EVENTS_BASE_URL)/install.yaml || true
	@echo "Deleting namespace $(ARGO_EVENTS_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(ARGO_EVENTS_NAMESPACE) --ignore-not-found=true || true
