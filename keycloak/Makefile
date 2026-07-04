include ../Makefile.env

KEYCLOAK_K8S_RESOURCES_REPO ?= https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources
KEYCLOAK_K8S_RESOURCES_VERSION ?= $(KEYCLOAK_OPERATOR_VERSION)
KEYCLOAK_CRD_URL ?= $(KEYCLOAK_K8S_RESOURCES_REPO)/$(KEYCLOAK_K8S_RESOURCES_VERSION)/kubernetes/keycloaks.k8s.keycloak.org-v1.yml
KEYCLOAK_REALM_IMPORT_CRD_URL ?= $(KEYCLOAK_K8S_RESOURCES_REPO)/$(KEYCLOAK_K8S_RESOURCES_VERSION)/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml
KEYCLOAK_OPERATOR_MANIFEST_URL ?= $(KEYCLOAK_K8S_RESOURCES_REPO)/$(KEYCLOAK_K8S_RESOURCES_VERSION)/kubernetes/kubernetes.yml
KEYCLOAK_ENV_FILE ?= ../secrets/keycloak.env

.PHONY: install uninstall full-uninstall install-operator uninstall-operator uninstall-crds install-postgresql uninstall-postgresql install-keycloak uninstall-keycloak-resource create-admin-secret create-db-secret apply-realms get-admin-password

install: install-operator install-postgresql create-db-secret create-admin-secret install-keycloak apply-realms

install-operator:
	@echo "Installing Keycloak Operator ($(KEYCLOAK_OPERATOR_VERSION))..."
	@$(KUBECTL) create namespace $(KEYCLOAK_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(KUBECTL) apply -f $(KEYCLOAK_CRD_URL)
	@$(KUBECTL) apply -f $(KEYCLOAK_REALM_IMPORT_CRD_URL)
	@$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) apply -f $(KEYCLOAK_OPERATOR_MANIFEST_URL)
	@if [ "$(KEYCLOAK_NAMESPACE)" != "keycloak" ]; then \
		echo "Patching operator namespace binding for $(KEYCLOAK_NAMESPACE)..."; \
		$(KUBECTL) patch clusterrolebinding keycloak-operator-clusterrole-binding --type='json' -p='[{"op":"replace","path":"/subjects/0/namespace","value":"$(KEYCLOAK_NAMESPACE)"}]'; \
		$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) rollout restart deployment/keycloak-operator; \
	fi
	@$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) rollout status deployment/keycloak-operator --timeout=600s

create-admin-secret:
	@$(KUBECTL) create namespace $(KEYCLOAK_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@if [ -n "$(KEYCLOAK_ADMIN_PASSWORD)" ]; then \
		PASS="$(KEYCLOAK_ADMIN_PASSWORD)"; \
	elif [ -f "$(KEYCLOAK_ENV_FILE)" ]; then \
		set -a; . "$(KEYCLOAK_ENV_FILE)"; set +a; \
		PASS="$$KEYCLOAK_ADMIN_PASSWORD"; \
	else \
		PASS=""; \
	fi; \
	if [ -z "$$PASS" ] && $(KUBECTL) -n $(KEYCLOAK_NAMESPACE) get secret $(KEYCLOAK_ADMIN_SECRET_NAME) >/dev/null 2>&1; then \
		echo "Bootstrap admin secret already exists; keeping current value."; \
		exit 0; \
	fi; \
	if [ -z "$$PASS" ]; then \
		echo "Error: provide KEYCLOAK_ADMIN_PASSWORD or create $(KEYCLOAK_ENV_FILE)"; \
		exit 1; \
	fi; \
	$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) create secret generic $(KEYCLOAK_ADMIN_SECRET_NAME) \
		--from-literal=username="$(KEYCLOAK_ADMIN_USERNAME)" \
		--from-literal=$(KEYCLOAK_ADMIN_SECRET_KEY)="$$PASS" \
		--dry-run=client -o yaml | $(KUBECTL) apply -f -

create-db-secret:
	@$(KUBECTL) create namespace $(KEYCLOAK_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@if [ -n "$(KEYCLOAK_DB_PASSWORD)" ]; then \
		PASS="$(KEYCLOAK_DB_PASSWORD)"; \
	elif [ -f "$(KEYCLOAK_ENV_FILE)" ]; then \
		set -a; . "$(KEYCLOAK_ENV_FILE)"; set +a; \
		PASS="$$KEYCLOAK_DB_PASSWORD"; \
	else \
		PASS=""; \
	fi; \
	if $(KUBECTL) -n $(KEYCLOAK_NAMESPACE) get secret $(KEYCLOAK_DB_SECRET_NAME) >/dev/null 2>&1 && [ -z "$$PASS" ]; then \
		echo "Database secret already exists; keeping current value."; \
		exit 0; \
	fi; \
	if [ -z "$$PASS" ]; then \
		PASS="$$(openssl rand -base64 24 | tr -d '\n')"; \
		echo "Generated database password for $(KEYCLOAK_DB_SECRET_NAME)."; \
	fi; \
	$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) create secret generic $(KEYCLOAK_DB_SECRET_NAME) \
		--from-literal=username="$(KEYCLOAK_DB_USERNAME)" \
		--from-literal=password="$$PASS" \
		--from-literal=database="$(KEYCLOAK_DB_NAME)" \
		--dry-run=client -o yaml | $(KUBECTL) apply -f -

install-postgresql: create-db-secret
	@echo "Installing PostgreSQL for Keycloak..."
	@export KEYCLOAK_DB_PORT="$(KEYCLOAK_DB_PORT)" \
		KEYCLOAK_DB_SERVICE_NAME="$(KEYCLOAK_DB_SERVICE_NAME)" && \
		envsubst '$$KEYCLOAK_DB_PORT $$KEYCLOAK_DB_SERVICE_NAME' < postgresql-service.yaml | $(KUBECTL) -n $(KEYCLOAK_NAMESPACE) apply -f -
	@export KEYCLOAK_DB_IMAGE="$(KEYCLOAK_DB_IMAGE)" \
			KEYCLOAK_DB_NAME="$(KEYCLOAK_DB_NAME)" \
			KEYCLOAK_DB_PORT="$(KEYCLOAK_DB_PORT)" \
			KEYCLOAK_DB_SECRET_NAME="$(KEYCLOAK_DB_SECRET_NAME)" \
			KEYCLOAK_DB_SERVICE_NAME="$(KEYCLOAK_DB_SERVICE_NAME)" \
			KEYCLOAK_DB_STORAGE_SIZE="$(KEYCLOAK_DB_STORAGE_SIZE)" && \
			envsubst '$$KEYCLOAK_DB_IMAGE $$KEYCLOAK_DB_NAME $$KEYCLOAK_DB_PORT $$KEYCLOAK_DB_SECRET_NAME $$KEYCLOAK_DB_SERVICE_NAME $$KEYCLOAK_DB_STORAGE_SIZE' < postgresql-statefulset.yaml | $(KUBECTL) -n $(KEYCLOAK_NAMESPACE) apply -f -
	@$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) rollout status statefulset/$(KEYCLOAK_DB_SERVICE_NAME) --timeout=600s

install-keycloak: create-admin-secret
	@echo "Installing Keycloak ($(KEYCLOAK_VERSION))..."
	@export KEYCLOAK_ADMIN_SECRET_NAME="$(KEYCLOAK_ADMIN_SECRET_NAME)" \
		KEYCLOAK_CR_NAME="$(KEYCLOAK_CR_NAME)" \
		KEYCLOAK_CANONICAL_HOST="$(KEYCLOAK_CANONICAL_HOST)" \
		KEYCLOAK_DB_NAME="$(KEYCLOAK_DB_NAME)" \
		KEYCLOAK_DB_PORT="$(KEYCLOAK_DB_PORT)" \
		KEYCLOAK_DB_SECRET_NAME="$(KEYCLOAK_DB_SECRET_NAME)" \
		KEYCLOAK_DB_SERVICE_NAME="$(KEYCLOAK_DB_SERVICE_NAME)" \
		KEYCLOAK_IMAGE="$(KEYCLOAK_IMAGE)" && \
		envsubst '$$KEYCLOAK_ADMIN_SECRET_NAME $$KEYCLOAK_CANONICAL_HOST $$KEYCLOAK_CR_NAME $$KEYCLOAK_DB_NAME $$KEYCLOAK_DB_PORT $$KEYCLOAK_DB_SECRET_NAME $$KEYCLOAK_DB_SERVICE_NAME $$KEYCLOAK_IMAGE' < keycloak.yaml | $(KUBECTL) -n $(KEYCLOAK_NAMESPACE) apply -f -
	@$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) wait --for=condition=Ready keycloaks.k8s.keycloak.org/$(KEYCLOAK_CR_NAME) --timeout=600s
	@echo "Applying Gateway configuration..."
	@export KEYCLOAK_NAMESPACE="$(KEYCLOAK_NAMESPACE)" \
		GATEWAY_NAMESPACE="$(GATEWAY_NAMESPACE)" \
		KEYCLOAK_HOST="$(KEYCLOAK_HOST)" \
		KEYCLOAK_PUBLIC_HOST="$(KEYCLOAK_PUBLIC_HOST)" \
		KEYCLOAK_SERVICE_NAME="$(KEYCLOAK_SERVICE_NAME)" && \
		envsubst '$$KEYCLOAK_NAMESPACE $$GATEWAY_NAMESPACE $$KEYCLOAK_HOST $$KEYCLOAK_PUBLIC_HOST $$KEYCLOAK_SERVICE_NAME' < gateway.yaml | $(KUBECTL) apply -f -

apply-realms:
	@echo "Applying Keycloak realm imports..."
	@export KEYCLOAK_CR_NAME="$(KEYCLOAK_CR_NAME)" && \
		envsubst '$$KEYCLOAK_CR_NAME' < realms/snd.yaml | $(KUBECTL) -n $(KEYCLOAK_NAMESPACE) apply -f -
	@export KEYCLOAK_CR_NAME="$(KEYCLOAK_CR_NAME)" && \
		envsubst '$$KEYCLOAK_CR_NAME' < realms/prd.yaml | $(KUBECTL) -n $(KEYCLOAK_NAMESPACE) apply -f -
	@$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) wait --for=jsonpath='{.status.conditions[?(@.type=="Done")].status}'=True keycloakrealmimport/snd-realm-import --timeout=$(KEYCLOAK_REALM_IMPORT_TIMEOUT)
	@$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) wait --for=jsonpath='{.status.conditions[?(@.type=="Done")].status}'=True keycloakrealmimport/prd-realm-import --timeout=$(KEYCLOAK_REALM_IMPORT_TIMEOUT)

get-admin-password:
	@$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) get secret $(KEYCLOAK_ADMIN_SECRET_NAME) -o jsonpath='{.data.$(KEYCLOAK_ADMIN_SECRET_KEY)}' | $(BASE64_DECODE)
	@echo ""

uninstall: uninstall-keycloak-resource uninstall-postgresql
	@echo "Deleting namespace $(KEYCLOAK_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(KEYCLOAK_NAMESPACE) --ignore-not-found=true || true

full-uninstall: uninstall uninstall-operator uninstall-crds

uninstall-keycloak-resource:
	@echo "Uninstalling Gateway configuration..."
	@export KEYCLOAK_NAMESPACE="$(KEYCLOAK_NAMESPACE)" \
		GATEWAY_NAMESPACE="$(GATEWAY_NAMESPACE)" \
		KEYCLOAK_HOST="$(KEYCLOAK_HOST)" \
		KEYCLOAK_PUBLIC_HOST="$(KEYCLOAK_PUBLIC_HOST)" \
		KEYCLOAK_SERVICE_NAME="$(KEYCLOAK_SERVICE_NAME)" && \
		envsubst '$$KEYCLOAK_NAMESPACE $$GATEWAY_NAMESPACE $$KEYCLOAK_HOST $$KEYCLOAK_PUBLIC_HOST $$KEYCLOAK_SERVICE_NAME' < gateway.yaml | $(KUBECTL) delete -f - --ignore-not-found=true || true
	@export KEYCLOAK_CR_NAME="$(KEYCLOAK_CR_NAME)" && \
		envsubst '$$KEYCLOAK_CR_NAME' < realms/snd.yaml | $(KUBECTL) -n $(KEYCLOAK_NAMESPACE) delete -f - --ignore-not-found=true || true
	@export KEYCLOAK_CR_NAME="$(KEYCLOAK_CR_NAME)" && \
		envsubst '$$KEYCLOAK_CR_NAME' < realms/prd.yaml | $(KUBECTL) -n $(KEYCLOAK_NAMESPACE) delete -f - --ignore-not-found=true || true
	@export KEYCLOAK_ADMIN_SECRET_NAME="$(KEYCLOAK_ADMIN_SECRET_NAME)" \
		KEYCLOAK_CR_NAME="$(KEYCLOAK_CR_NAME)" \
		KEYCLOAK_CANONICAL_HOST="$(KEYCLOAK_CANONICAL_HOST)" \
		KEYCLOAK_DB_NAME="$(KEYCLOAK_DB_NAME)" \
		KEYCLOAK_DB_PORT="$(KEYCLOAK_DB_PORT)" \
		KEYCLOAK_DB_SECRET_NAME="$(KEYCLOAK_DB_SECRET_NAME)" \
		KEYCLOAK_DB_SERVICE_NAME="$(KEYCLOAK_DB_SERVICE_NAME)" \
		KEYCLOAK_IMAGE="$(KEYCLOAK_IMAGE)" && \
		envsubst '$$KEYCLOAK_ADMIN_SECRET_NAME $$KEYCLOAK_CANONICAL_HOST $$KEYCLOAK_CR_NAME $$KEYCLOAK_DB_NAME $$KEYCLOAK_DB_PORT $$KEYCLOAK_DB_SECRET_NAME $$KEYCLOAK_DB_SERVICE_NAME $$KEYCLOAK_IMAGE' < keycloak.yaml | $(KUBECTL) -n $(KEYCLOAK_NAMESPACE) delete -f - --ignore-not-found=true || true

uninstall-postgresql:
	@echo "Uninstalling PostgreSQL for Keycloak..."
	@export KEYCLOAK_DB_PORT="$(KEYCLOAK_DB_PORT)" \
		KEYCLOAK_DB_SERVICE_NAME="$(KEYCLOAK_DB_SERVICE_NAME)" && \
		envsubst '$$KEYCLOAK_DB_PORT $$KEYCLOAK_DB_SERVICE_NAME' < postgresql-service.yaml | $(KUBECTL) -n $(KEYCLOAK_NAMESPACE) delete -f - --ignore-not-found=true || true
	@export KEYCLOAK_DB_IMAGE="$(KEYCLOAK_DB_IMAGE)" \
		KEYCLOAK_DB_NAME="$(KEYCLOAK_DB_NAME)" \
		KEYCLOAK_DB_PORT="$(KEYCLOAK_DB_PORT)" \
		KEYCLOAK_DB_SECRET_NAME="$(KEYCLOAK_DB_SECRET_NAME)" \
		KEYCLOAK_DB_SERVICE_NAME="$(KEYCLOAK_DB_SERVICE_NAME)" \
		KEYCLOAK_DB_STORAGE_SIZE="$(KEYCLOAK_DB_STORAGE_SIZE)" && \
		envsubst '$$KEYCLOAK_DB_IMAGE $$KEYCLOAK_DB_NAME $$KEYCLOAK_DB_PORT $$KEYCLOAK_DB_SECRET_NAME $$KEYCLOAK_DB_SERVICE_NAME $$KEYCLOAK_DB_STORAGE_SIZE' < postgresql-statefulset.yaml | $(KUBECTL) -n $(KEYCLOAK_NAMESPACE) delete -f - --ignore-not-found=true || true
	@$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) delete secret $(KEYCLOAK_DB_SECRET_NAME) --ignore-not-found=true || true
	@$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) delete pvc data-$(KEYCLOAK_DB_SERVICE_NAME)-0 --ignore-not-found=true || true

uninstall-operator:
	@echo "Uninstalling Keycloak Operator..."
	@$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) delete -f $(KEYCLOAK_OPERATOR_MANIFEST_URL) --ignore-not-found=true || true
	@$(KUBECTL) -n $(KEYCLOAK_NAMESPACE) delete secret $(KEYCLOAK_ADMIN_SECRET_NAME) --ignore-not-found=true || true

uninstall-crds:
	@echo "Uninstalling Keycloak CRDs..."
	@$(KUBECTL) delete -f $(KEYCLOAK_REALM_IMPORT_CRD_URL) --ignore-not-found=true || true
	@$(KUBECTL) delete -f $(KEYCLOAK_CRD_URL) --ignore-not-found=true || true
