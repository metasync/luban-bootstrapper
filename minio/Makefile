include ../Makefile.env

.PHONY: install uninstall check

MINIO_REPO_URL ?= https://charts.min.io/

install:
	@if [ ! -f ../secrets/minio.env ]; then echo "Missing ../secrets/minio.env (create it with MINIO_ROOT_USER and MINIO_ROOT_PASSWORD)"; exit 1; fi
	@$(KUBECTL) create namespace $(MINIO_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@echo "Creating/Updating MinIO auth secret..."
	@set -a; . ../secrets/minio.env; set +a; \
		$(KUBECTL) -n $(MINIO_NAMESPACE) create secret generic minio-auth \
			--from-literal=rootUser="$$MINIO_ROOT_USER" \
			--from-literal=rootPassword="$$MINIO_ROOT_PASSWORD" \
			--dry-run=client -o yaml | $(KUBECTL) apply -f -
	@echo "Adding MinIO Helm repository..."
	@helm repo add minio $(MINIO_REPO_URL)
	@helm repo update minio
	@echo "Installing MinIO (Chart v$(MINIO_CHART_VERSION))..."
	@helm upgrade --install $(MINIO_RELEASE_NAME) minio/minio \
		--namespace $(MINIO_NAMESPACE) \
		--create-namespace \
		--version $(MINIO_CHART_VERSION) \
		--values values.yaml \
		--wait --wait-for-jobs
	@echo "Applying Gateway configuration for MinIO Console..."
	@export MINIO_NAMESPACE=$(MINIO_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		MINIO_HOST=$(MINIO_HOST) \
		MINIO_PUBLIC_HOST=$(MINIO_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) apply -f -

check:
	@echo "Checking MinIO readiness..."
	@$(KUBECTL) -n $(MINIO_NAMESPACE) get secret minio-auth >/dev/null
	@$(KUBECTL) -n $(MINIO_NAMESPACE) wait --for=condition=Ready pod -l release=$(MINIO_RELEASE_NAME) --timeout=300s

uninstall:
	@echo "Uninstalling Gateway configuration..."
	@export MINIO_NAMESPACE=$(MINIO_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		MINIO_HOST=$(MINIO_HOST) \
		MINIO_PUBLIC_HOST=$(MINIO_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) delete -f - --ignore-not-found=true || true
	@echo "Uninstalling MinIO..."
	@helm uninstall $(MINIO_RELEASE_NAME) -n $(MINIO_NAMESPACE) || true
	@echo "Deleting namespace $(MINIO_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(MINIO_NAMESPACE) --ignore-not-found=true || true
