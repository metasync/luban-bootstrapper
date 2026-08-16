include ../Makefile.env
include ../cli/common.mk

.PHONY: install uninstall check build-image version

MINIO_REPO_URL ?= https://charts.min.io/

# Purge control (default = 0, keep MinIO PVC / all buckets + data on uninstall)
PURGE_DATA ?= 0

install:
	@if [ ! -f ../secrets/minio.env ]; then echo "Missing ../secrets/minio.env (create it with MINIO_ROOT_USER and MINIO_ROOT_PASSWORD)"; exit 1; fi
	@docker image inspect $(MINIO_IMAGE_REPOSITORY):$(MINIO_IMAGE_TAG) >/dev/null 2>&1 || $(MAKE) build-image
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
	@TMP_VALUES=$$(mktemp /tmp/minio-values.XXXXXX); \
		env \
			MINIO_IMAGE_REPOSITORY="$(MINIO_IMAGE_REPOSITORY)" \
			MINIO_IMAGE_TAG="$(MINIO_IMAGE_TAG)" \
			MINIO_MC_IMAGE_REPOSITORY="$(MINIO_MC_IMAGE_REPOSITORY)" \
			MINIO_MC_IMAGE_TAG="$(MINIO_MC_IMAGE_TAG)" \
			envsubst < values.yaml > $$TMP_VALUES; \
		helm upgrade --install $(MINIO_RELEASE_NAME) minio/minio \
		--namespace $(MINIO_NAMESPACE) \
		--create-namespace \
		--version $(MINIO_CHART_VERSION) \
		--values $$TMP_VALUES \
		--timeout 10m
	@rm -f $$TMP_VALUES
	@$(KUBECTL) -n $(MINIO_NAMESPACE) rollout status deployment/$(MINIO_RELEASE_NAME) --timeout=600s
	@jobs="$$( $(KUBECTL) -n $(MINIO_NAMESPACE) get jobs -l release=$(MINIO_RELEASE_NAME) -o name 2>/dev/null )"; \
		if [ -n "$$jobs" ]; then $(KUBECTL) -n $(MINIO_NAMESPACE) wait --for=condition=complete --timeout=600s $$jobs; fi
	@echo "Applying Gateway configuration for MinIO Console..."
	@export MINIO_NAMESPACE=$(MINIO_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		MINIO_HOST=$(MINIO_HOST) \
		MINIO_PUBLIC_HOST=$(MINIO_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) apply -f -

build-image:
	@command -v git >/dev/null 2>&1 || (echo "Missing git"; exit 1)
	@command -v go >/dev/null 2>&1 || (echo "Missing go"; exit 1)
	@ARCH=$$(docker version -f '{{.Server.Arch}}' 2>/dev/null || docker info -f '{{.Architecture}}' 2>/dev/null || uname -m); \
		case $$ARCH in \
			aarch64|arm64) GOARCH=arm64 ;; \
			x86_64|amd64) GOARCH=amd64 ;; \
			*) echo "Unsupported architecture: $$ARCH"; exit 1 ;; \
		esac; \
		TMP_DIR=$$(mktemp -d /tmp/minio-src.XXXXXX); \
		git clone --depth 1 --branch $(MINIO_IMAGE_TAG) https://github.com/minio/minio.git $$TMP_DIR >/dev/null; \
		cd $$TMP_DIR; \
		VERSION="$$(echo "$(MINIO_IMAGE_TAG)" | sed -E 's/^RELEASE\.//; s/T([0-9]{2})-([0-9]{2})-([0-9]{2})Z/T\1:\2:\3Z/')"; \
		export GOPATH=/tmp/gopath GOCACHE=/tmp/gocache; \
		mkdir -p $$GOPATH $$GOCACHE; \
		LDFLAGS="$$(MINIO_RELEASE=RELEASE MINIO_HOTFIX= go run buildscripts/gen-ldflags.go $$VERSION)"; \
		CGO_ENABLED=0 GOOS=linux GOARCH=$$GOARCH go build -trimpath -tags kqueue --ldflags "$$LDFLAGS" -o minio 1>/dev/null; \
		docker build -q --no-cache -t $(MINIO_IMAGE_REPOSITORY):$(MINIO_IMAGE_TAG) . -f Dockerfile >/dev/null; \
		rm -rf $$TMP_DIR

check:
	@echo "Checking MinIO readiness..."
	@$(KUBECTL) -n $(MINIO_NAMESPACE) get secret minio-auth >/dev/null
	@$(KUBECTL) -n $(MINIO_NAMESPACE) wait --for=condition=Ready pod -l release=$(MINIO_RELEASE_NAME) --timeout=300s

version:
	@echo "Local image: $(MINIO_IMAGE_REPOSITORY):$(MINIO_IMAGE_TAG)"
	@docker image inspect $(MINIO_IMAGE_REPOSITORY):$(MINIO_IMAGE_TAG) >/dev/null 2>&1 && \
		docker run --rm --entrypoint /usr/bin/minio $(MINIO_IMAGE_REPOSITORY):$(MINIO_IMAGE_TAG) --version || \
		echo "Local image not found"
	@echo "---"
	@POD=$$( $(KUBECTL) -n $(MINIO_NAMESPACE) get pods -l release=$(MINIO_RELEASE_NAME) -o jsonpath='{.items[0].metadata.name}' 2>/dev/null ); \
		if [ -z "$$POD" ]; then echo "No running pod in namespace $(MINIO_NAMESPACE)"; exit 0; fi; \
		IMG=$$( $(KUBECTL) -n $(MINIO_NAMESPACE) get pod $$POD -o jsonpath='{.spec.containers[0].image}' ); \
		echo "Cluster pod: $$POD"; \
		echo "Cluster image: $$IMG"; \
		$(KUBECTL) -n $(MINIO_NAMESPACE) logs $$POD --tail=25 | egrep '^(MinIO Object Storage Server|Version:|API:|WebUI:|WARN:|INFO:|ERROR:)' || true

uninstall:
	@echo "Uninstalling Gateway configuration..."
	@export MINIO_NAMESPACE=$(MINIO_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		MINIO_HOST=$(MINIO_HOST) \
		MINIO_PUBLIC_HOST=$(MINIO_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) delete -f - --ignore-not-found=true || true
	@echo "Uninstalling MinIO (Helm release)..."
	@helm uninstall $(MINIO_RELEASE_NAME) -n $(MINIO_NAMESPACE) || true
	$(call purge-namespace,$(MINIO_NAMESPACE))
