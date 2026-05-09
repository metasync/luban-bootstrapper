include ../Makefile.env

.PHONY: install uninstall install-operator uninstall-operator install-stack uninstall-stack install-fleet-apm uninstall-fleet-apm get-elastic-password

ELASTIC_REPO_URL ?= https://helm.elastic.co
ECK_OPERATOR_RELEASE_NAME ?= elastic-operator

ELASTICSEARCH_NAME ?= elasticsearch
KIBANA_NAME ?= kibana

install: install-operator install-stack

install-fleet-apm: install
	@$(KUBECTL) create namespace $(ELASTIC_STACK_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@echo "Ensuring Kibana encryption keys secret exists..."
	@if ! $(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) get secret $(KIBANA_ENCRYPTION_SECRET_NAME) >/dev/null 2>&1; then \
		$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) create secret generic $(KIBANA_ENCRYPTION_SECRET_NAME) \
			--from-literal=encryptedSavedObjectsKey=$$(openssl rand -hex 32) \
			--from-literal=securityKey=$$(openssl rand -hex 32) \
			--from-literal=reportingKey=$$(openssl rand -hex 32) \
			--dry-run=client -o yaml | $(KUBECTL) apply -f -; \
	fi
	@if [ "$(FORCE)" != "1" ] && $(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) get agent/$(FLEET_SERVER_NAME) >/dev/null 2>&1; then \
		echo "fleet-apm already installed (set FORCE=1 to re-apply)"; \
	else \
		echo "Applying Kibana Fleet configuration..."; \
		export ELASTIC_STACK_VERSION=$(ELASTIC_STACK_VERSION) \
			ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
			ELASTICSEARCH_NAME=$(ELASTICSEARCH_NAME) \
			KIBANA_NAME=$(KIBANA_NAME) \
			KIBANA_PUBLIC_BASE_URL=$(KIBANA_PUBLIC_BASE_URL) \
			FLEET_SERVER_NAME=$(FLEET_SERVER_NAME) \
			FLEET_SERVER_POLICY_ID=$(FLEET_SERVER_POLICY_ID) \
			ELASTIC_AGENT_POLICY_ID=$(ELASTIC_AGENT_POLICY_ID) \
			FLEET_DATA_NAMESPACE=$(FLEET_DATA_NAMESPACE) \
			KIBANA_ENCRYPTION_SECRET_NAME=$(KIBANA_ENCRYPTION_SECRET_NAME) && \
			envsubst '$$ELASTIC_STACK_VERSION $$ELASTIC_STACK_NAMESPACE $$ELASTICSEARCH_NAME $$KIBANA_NAME $$KIBANA_PUBLIC_BASE_URL $$FLEET_SERVER_NAME $$FLEET_SERVER_POLICY_ID $$ELASTIC_AGENT_POLICY_ID $$FLEET_DATA_NAMESPACE $$KIBANA_ENCRYPTION_SECRET_NAME' < kibana-fleet.yaml | $(KUBECTL) apply -f -; \
		echo "Waiting for Kibana to be ready..."; \
		$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) wait --for=jsonpath='{.status.health}'=green kibana/$(KIBANA_NAME) --timeout=10m; \
		echo "Applying Fleet Server + APM integration (Elastic Agent)..."; \
		export ELASTIC_STACK_VERSION=$(ELASTIC_STACK_VERSION) \
			ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
			ELASTICSEARCH_NAME=$(ELASTICSEARCH_NAME) \
			KIBANA_NAME=$(KIBANA_NAME) \
			FLEET_SERVER_NAME=$(FLEET_SERVER_NAME) \
			ELASTIC_AGENT_NAME=$(ELASTIC_AGENT_NAME) \
			FLEET_SERVER_POLICY_ID=$(FLEET_SERVER_POLICY_ID) \
			ELASTIC_AGENT_POLICY_ID=$(ELASTIC_AGENT_POLICY_ID) \
			APM_FLEET_SERVICE_NAME=$(APM_FLEET_SERVICE_NAME) && \
			envsubst '$$ELASTIC_STACK_VERSION $$ELASTIC_STACK_NAMESPACE $$ELASTICSEARCH_NAME $$KIBANA_NAME $$FLEET_SERVER_NAME $$ELASTIC_AGENT_NAME $$FLEET_SERVER_POLICY_ID $$ELASTIC_AGENT_POLICY_ID $$APM_FLEET_SERVICE_NAME' < fleet-apm.yaml | $(KUBECTL) apply -f -; \
		echo "Waiting for Fleet Server and Elastic Agent to be ready..."; \
		$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) wait --for=jsonpath='{.status.health}'=green agent/$(FLEET_SERVER_NAME) --timeout=10m; \
		$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) wait --for=jsonpath='{.status.health}'=green agent/$(ELASTIC_AGENT_NAME) --timeout=10m; \
	fi
	@echo "Applying Gateway configuration for Kibana + Fleet-managed APM..."
	@export ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		KIBANA_HOST=$(KIBANA_HOST) \
		KIBANA_PUBLIC_HOST=$(KIBANA_PUBLIC_HOST) \
		KIBANA_SERVICE_NAME=$(KIBANA_NAME)-kb-http && \
		envsubst '$$ELASTIC_STACK_NAMESPACE $$GATEWAY_NAMESPACE $$KIBANA_HOST $$KIBANA_PUBLIC_HOST $$KIBANA_SERVICE_NAME' < gateway-kibana.yaml | $(KUBECTL) apply -f -
	@export ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		APM_HOST=$(APM_HOST) \
		APM_PUBLIC_HOST=$(APM_PUBLIC_HOST) \
		APM_SERVICE_NAME=$(APM_FLEET_SERVICE_NAME) && \
		envsubst '$$ELASTIC_STACK_NAMESPACE $$GATEWAY_NAMESPACE $$APM_HOST $$APM_PUBLIC_HOST $$APM_SERVICE_NAME' < gateway-apm.yaml | $(KUBECTL) apply -f -

install-operator:
	@if [ "$(FORCE)" != "1" ] && helm status $(ECK_OPERATOR_RELEASE_NAME) -n $(ELASTIC_SYSTEM_NAMESPACE) >/dev/null 2>&1; then \
		echo "eck-operator already installed (set FORCE=1 to upgrade)"; \
	else \
		echo "Adding Elastic Helm repository..."; \
		helm repo add elastic $(ELASTIC_REPO_URL); \
		helm repo update elastic; \
		echo "Installing ECK Operator (Chart v$(ECK_OPERATOR_CHART_VERSION))..."; \
		helm upgrade --install $(ECK_OPERATOR_RELEASE_NAME) elastic/eck-operator \
			--namespace $(ELASTIC_SYSTEM_NAMESPACE) \
			--create-namespace \
			--version $(ECK_OPERATOR_CHART_VERSION) \
			--timeout 10m \
			--wait; \
		$(KUBECTL) -n $(ELASTIC_SYSTEM_NAMESPACE) rollout status statefulset/elastic-operator --timeout=600s; \
	fi

install-stack:
	@if [ "$(FORCE)" != "1" ] && $(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) get elasticsearch/$(ELASTICSEARCH_NAME) >/dev/null 2>&1; then \
		echo "elastic-stack already installed (set FORCE=1 to re-apply resources)"; \
	else \
		$(KUBECTL) create namespace $(ELASTIC_STACK_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -; \
		echo "Ensuring Kibana encryption keys secret exists..."; \
		if ! $(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) get secret $(KIBANA_ENCRYPTION_SECRET_NAME) >/dev/null 2>&1; then \
			$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) create secret generic $(KIBANA_ENCRYPTION_SECRET_NAME) \
				--from-literal=encryptedSavedObjectsKey=$$(openssl rand -hex 32) \
				--from-literal=securityKey=$$(openssl rand -hex 32) \
				--from-literal=reportingKey=$$(openssl rand -hex 32) \
				--dry-run=client -o yaml | $(KUBECTL) apply -f -; \
		fi; \
		echo "Applying Elasticsearch and Kibana manifests..."; \
		export ELASTIC_STACK_VERSION=$(ELASTIC_STACK_VERSION) \
			ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
			ELASTICSEARCH_NAME=$(ELASTICSEARCH_NAME) \
			KIBANA_NAME=$(KIBANA_NAME) && \
			envsubst '$$ELASTIC_STACK_VERSION $$ELASTIC_STACK_NAMESPACE $$ELASTICSEARCH_NAME' < elasticsearch.yaml | $(KUBECTL) apply -f -; \
		export ELASTIC_STACK_VERSION=$(ELASTIC_STACK_VERSION) \
			ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
			ELASTICSEARCH_NAME=$(ELASTICSEARCH_NAME) \
			KIBANA_NAME=$(KIBANA_NAME) \
			KIBANA_PUBLIC_BASE_URL=$(KIBANA_PUBLIC_BASE_URL) \
			KIBANA_ENCRYPTION_SECRET_NAME=$(KIBANA_ENCRYPTION_SECRET_NAME) && \
			envsubst '$$ELASTIC_STACK_VERSION $$ELASTIC_STACK_NAMESPACE $$ELASTICSEARCH_NAME $$KIBANA_NAME $$KIBANA_PUBLIC_BASE_URL $$KIBANA_ENCRYPTION_SECRET_NAME' < kibana.yaml | $(KUBECTL) apply -f -; \
		echo "Waiting for Elasticsearch and Kibana to be ready..."; \
		$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) wait --for=jsonpath='{.status.phase}'=Ready elasticsearch/$(ELASTICSEARCH_NAME) --timeout=10m; \
		$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) wait --for=jsonpath='{.status.health}'=green kibana/$(KIBANA_NAME) --timeout=10m; \
	fi
	@echo "Applying Gateway configuration for Kibana..."
	@export ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		KIBANA_HOST=$(KIBANA_HOST) \
		KIBANA_PUBLIC_HOST=$(KIBANA_PUBLIC_HOST) \
		KIBANA_SERVICE_NAME=$(KIBANA_NAME)-kb-http && \
		envsubst '$$ELASTIC_STACK_NAMESPACE $$GATEWAY_NAMESPACE $$KIBANA_HOST $$KIBANA_PUBLIC_HOST $$KIBANA_SERVICE_NAME' < gateway-kibana.yaml | $(KUBECTL) apply -f -

uninstall-fleet-apm:
	@echo "Deleting Fleet Server + Elastic Agent resources..."
	@export ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
		FLEET_SERVER_NAME=$(FLEET_SERVER_NAME) \
		ELASTIC_AGENT_NAME=$(ELASTIC_AGENT_NAME) \
		APM_FLEET_SERVICE_NAME=$(APM_FLEET_SERVICE_NAME) && \
		envsubst '$$ELASTIC_STACK_NAMESPACE $$FLEET_SERVER_NAME $$ELASTIC_AGENT_NAME $$APM_FLEET_SERVICE_NAME' < fleet-apm.yaml | $(KUBECTL) delete -f - --ignore-not-found=true || true

get-elastic-password:
	@$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) get secret $(ELASTICSEARCH_NAME)-es-elastic-user -o jsonpath='{.data.elastic}' | $(BASE64_DECODE)

uninstall: uninstall-stack uninstall-operator

uninstall-stack:
	@$(MAKE) uninstall-fleet-apm
	@echo "Uninstalling Gateway configuration for Kibana + APM..."
	@export ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		APM_HOST=$(APM_HOST) \
		APM_PUBLIC_HOST=$(APM_PUBLIC_HOST) \
		APM_SERVICE_NAME=$(APM_FLEET_SERVICE_NAME) && \
		envsubst '$$ELASTIC_STACK_NAMESPACE $$GATEWAY_NAMESPACE $$APM_HOST $$APM_PUBLIC_HOST $$APM_SERVICE_NAME' < gateway-apm.yaml | $(KUBECTL) delete -f - --ignore-not-found=true || true
	@export ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		KIBANA_HOST=$(KIBANA_HOST) \
		KIBANA_PUBLIC_HOST=$(KIBANA_PUBLIC_HOST) \
		KIBANA_SERVICE_NAME=$(KIBANA_NAME)-kb-http && \
		envsubst '$$ELASTIC_STACK_NAMESPACE $$GATEWAY_NAMESPACE $$KIBANA_HOST $$KIBANA_PUBLIC_HOST $$KIBANA_SERVICE_NAME' < gateway-kibana.yaml | $(KUBECTL) delete -f - --ignore-not-found=true || true
	@echo "Deleting Kibana and Elasticsearch resources..."
	@$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) delete kibana $(KIBANA_NAME) --ignore-not-found=true || true
	@$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) delete elasticsearch $(ELASTICSEARCH_NAME) --ignore-not-found=true || true
	@echo "Deleting namespace $(ELASTIC_STACK_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(ELASTIC_STACK_NAMESPACE) --ignore-not-found=true || true

uninstall-operator:
	@echo "Uninstalling ECK Operator..."
	@helm uninstall $(ECK_OPERATOR_RELEASE_NAME) -n $(ELASTIC_SYSTEM_NAMESPACE) || true
	@echo "Deleting namespace $(ELASTIC_SYSTEM_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(ELASTIC_SYSTEM_NAMESPACE) --ignore-not-found=true || true
