include ../Makefile.env

.PHONY: install uninstall install-operator uninstall-operator install-stack uninstall-stack install-apm-server uninstall-apm-server get-elastic-password get-apm-secret-token

ELASTIC_REPO_URL ?= https://helm.elastic.co
ECK_OPERATOR_RELEASE_NAME ?= elastic-operator

ELASTICSEARCH_NAME ?= elasticsearch
KIBANA_NAME ?= kibana

install: install-operator install-stack

install-apm-server:
	@if [ "$(FORCE)" != "1" ] && $(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) get apmserver/$(APM_SERVER_NAME) >/dev/null 2>&1; then \
		echo "apm-server already installed (set FORCE=1 to re-apply)"; \
	else \
		echo "Applying APM Server manifest..."; \
		export ELASTIC_STACK_VERSION=$(ELASTIC_STACK_VERSION) \
			ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
			ELASTICSEARCH_NAME=$(ELASTICSEARCH_NAME) \
			KIBANA_NAME=$(KIBANA_NAME) \
			APM_SERVER_NAME=$(APM_SERVER_NAME) && \
			envsubst < apm-server.yaml | $(KUBECTL) apply -f -; \
		echo "Waiting for APM Server to be ready..."; \
		$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) wait --for=jsonpath='{.status.health}'=green apmserver/$(APM_SERVER_NAME) --timeout=10m; \
	fi

uninstall-apm-server:
	@echo "Deleting APM Server resource..."
	@$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) delete apmserver $(APM_SERVER_NAME) --ignore-not-found=true || true

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
		echo "Applying Elasticsearch and Kibana manifests..."; \
		export ELASTIC_STACK_VERSION=$(ELASTIC_STACK_VERSION) \
			ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
			ELASTICSEARCH_NAME=$(ELASTICSEARCH_NAME) \
			KIBANA_NAME=$(KIBANA_NAME) && \
			envsubst < elasticsearch.yaml | $(KUBECTL) apply -f -; \
		export ELASTIC_STACK_VERSION=$(ELASTIC_STACK_VERSION) \
			ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
			ELASTICSEARCH_NAME=$(ELASTICSEARCH_NAME) \
			KIBANA_NAME=$(KIBANA_NAME) && \
			envsubst < kibana.yaml | $(KUBECTL) apply -f -; \
		echo "Waiting for Elasticsearch and Kibana to be ready..."; \
		$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) wait --for=jsonpath='{.status.phase}'=Ready elasticsearch/$(ELASTICSEARCH_NAME) --timeout=10m; \
		$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) wait --for=jsonpath='{.status.health}'=green kibana/$(KIBANA_NAME) --timeout=10m; \
	fi
	@echo "Applying Gateway configuration for Kibana..."
	@export ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		KIBANA_HOST=$(KIBANA_HOST) \
		KIBANA_PUBLIC_HOST=$(KIBANA_PUBLIC_HOST) \
		KIBANA_SERVICE_NAME=$(KIBANA_NAME)-kb-http \
		APM_HOST=$(APM_HOST) \
		APM_PUBLIC_HOST=$(APM_PUBLIC_HOST) \
		APM_SERVICE_NAME=$(APM_SERVER_NAME)-apm-http && \
		envsubst < gateway.yaml | $(KUBECTL) apply -f -

get-elastic-password:
	@$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) get secret $(ELASTICSEARCH_NAME)-es-elastic-user -o jsonpath='{.data.elastic}' | base64 -D

get-apm-secret-token:
	@$(KUBECTL) -n $(ELASTIC_STACK_NAMESPACE) get secret $(APM_SERVER_NAME)-apm-token -o jsonpath='{.data.secret-token}' | base64 -D

uninstall: uninstall-stack uninstall-operator

uninstall-stack:
	@echo "Uninstalling Gateway configuration for Kibana..."
	@export ELASTIC_STACK_NAMESPACE=$(ELASTIC_STACK_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		KIBANA_HOST=$(KIBANA_HOST) \
		KIBANA_PUBLIC_HOST=$(KIBANA_PUBLIC_HOST) \
		KIBANA_SERVICE_NAME=$(KIBANA_NAME)-kb-http \
		APM_HOST=$(APM_HOST) \
		APM_PUBLIC_HOST=$(APM_PUBLIC_HOST) \
		APM_SERVICE_NAME=$(APM_SERVER_NAME)-apm-http && \
		envsubst < gateway.yaml | $(KUBECTL) delete -f - --ignore-not-found=true || true
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
