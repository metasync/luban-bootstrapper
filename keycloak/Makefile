include ../Makefile.env

KEYCLOAK_CHART_URL ?= oci://registry-1.docker.io/bitnamicharts/keycloak

.PHONY: install uninstall create-admin-secret get-admin-password

create-admin-secret:
	@if [ -n "$(KEYCLOAK_ADMIN_PASSWORD)" ]; then \
		PASS="$(KEYCLOAK_ADMIN_PASSWORD)"; \
	elif [ -f ../secrets/keycloak.env ]; then \
		set -a; . ../secrets/keycloak.env; set +a; \
		PASS="$$KEYCLOAK_ADMIN_PASSWORD"; \
	else \
		echo "Error: provide KEYCLOAK_ADMIN_PASSWORD or create ../secrets/keycloak.env"; \
		exit 1; \
	fi; \
	if [ -z "$$PASS" ]; then \
		echo "Error: KEYCLOAK_ADMIN_PASSWORD is empty"; \
		exit 1; \
	fi; \
	$(KUBECTL) create namespace $(KEYCLOAK_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -; \
	$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) create secret generic $(KEYCLOAK_ADMIN_SECRET_NAME) \
		--from-literal=$(KEYCLOAK_ADMIN_SECRET_KEY)="$$PASS" \
		--dry-run=client -o yaml | $(KUBECTL) apply -f -

install: create-admin-secret
	@echo "Installing Keycloak (Chart v$(KEYCLOAK_CHART_VERSION))..."
	@helm upgrade --install $(KEYCLOAK_RELEASE_NAME) $(KEYCLOAK_CHART_URL) \
		--namespace $(KEYCLOAK_NAMESPACE) \
		--create-namespace \
		--version $(KEYCLOAK_CHART_VERSION) \
		--values values.yaml \
		--set auth.existingSecret=$(KEYCLOAK_ADMIN_SECRET_NAME) \
		--set auth.passwordSecretKey=$(KEYCLOAK_ADMIN_SECRET_KEY) \
		--wait \
		--timeout 10m
	@echo "Waiting for Keycloak rollout..."
	@$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) rollout status statefulset/$(KEYCLOAK_SERVICE_NAME) --timeout=600s
	@echo "Applying Gateway configuration..."
	@export KEYCLOAK_NAMESPACE=$(KEYCLOAK_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		KEYCLOAK_HOST=$(KEYCLOAK_HOST) \
		KEYCLOAK_PUBLIC_HOST=$(KEYCLOAK_PUBLIC_HOST) \
		KEYCLOAK_SERVICE_NAME=$(KEYCLOAK_SERVICE_NAME) && \
		envsubst < gateway.yaml | $(KUBECTL) apply -f -

get-admin-password:
	@$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) get secret $(KEYCLOAK_ADMIN_SECRET_NAME) -o jsonpath='{.data.$(KEYCLOAK_ADMIN_SECRET_KEY)}' | $(BASE64_DECODE)
	@echo ""

uninstall:
	@echo "Uninstalling Gateway configuration..."
	@export KEYCLOAK_NAMESPACE=$(KEYCLOAK_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		KEYCLOAK_HOST=$(KEYCLOAK_HOST) \
		KEYCLOAK_PUBLIC_HOST=$(KEYCLOAK_PUBLIC_HOST) \
		KEYCLOAK_SERVICE_NAME=$(KEYCLOAK_SERVICE_NAME) && \
		envsubst < gateway.yaml | $(KUBECTL) delete -f - --ignore-not-found=true || true
	@echo "Uninstalling Keycloak..."
	@helm uninstall $(KEYCLOAK_RELEASE_NAME) -n $(KEYCLOAK_NAMESPACE) || true
	@echo "Deleting namespace $(KEYCLOAK_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(KEYCLOAK_NAMESPACE) --ignore-not-found=true || true
