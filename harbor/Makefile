include ../Makefile.env

# Harbor installation and Gateway routing configuration.
# Installs Harbor using the official Helm chart and configures an HTTPS
# route via Envoy Gateway.

HARBOR_REPO_URL ?= https://helm.goharbor.io

.PHONY: install uninstall

install:
	@echo "Adding Harbor Helm repository..."
	@helm repo add harbor $(HARBOR_REPO_URL)
	@helm repo update harbor
	@echo "Installing Harbor (Chart v$(HARBOR_CHART_VERSION))..."
	@helm upgrade --install harbor harbor/harbor \
		--namespace $(HARBOR_NAMESPACE) \
		--create-namespace \
		--version $(HARBOR_CHART_VERSION) \
		--set externalURL=https://$(HARBOR_HOST) \
		--set expose.type=clusterIP \
		--set expose.tls.enabled=false \
		--set persistence.enabled=true \
		--timeout 10m \
		--wait
	@echo "Applying Gateway configuration..."
	@export HARBOR_NAMESPACE=$(HARBOR_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		HARBOR_HOST=$(HARBOR_HOST) \
		HARBOR_PUBLIC_HOST=$(HARBOR_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) apply -f -

get-password:
	@echo "Retrieving Harbor admin password..."
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) get secret harbor-core -o jsonpath='{.data.HARBOR_ADMIN_PASSWORD}' | base64 -D
	@echo ""

uninstall:
	@echo "Uninstalling Gateway configuration..."
	@export HARBOR_NAMESPACE=$(HARBOR_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		HARBOR_HOST=$(HARBOR_HOST) \
		HARBOR_PUBLIC_HOST=$(HARBOR_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) delete -f - --ignore-not-found=true || true
	@echo "Uninstalling Harbor..."
	@helm uninstall harbor -n $(HARBOR_NAMESPACE) || true
	@echo "Deleting namespace $(HARBOR_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(HARBOR_NAMESPACE) --ignore-not-found=true || true
