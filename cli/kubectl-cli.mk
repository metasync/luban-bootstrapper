# --- Kubectl CLI variables ---
# kubectl uses 'darwin'/'linux' and 'amd64'/'arm64' (same as Helm)

KUBECTL_ARCH := $(ARCH)

ifeq ($(ARCH),x86_64)
	KUBECTL_ARCH := amd64
endif
ifneq ($(filter arm64 aarch64,$(ARCH)),)
	KUBECTL_ARCH := arm64
endif

KUBECTL_URL := https://dl.k8s.io/release/v$(KUBECTL_CLI_VERSION)/bin/$(OS)/$(KUBECTL_ARCH)/kubectl

.PHONY: install-kubectl-cli download-and-install-kubectl-cli

install-kubectl-cli:
	@if command -v kubectl >/dev/null 2>&1; then \
		CURRENT_VERSION=$$(kubectl version --client -o json | grep gitVersion | cut -d'"' -f4 | tr -d 'v'); \
		if echo "$$CURRENT_VERSION" | grep -q "^$(KUBECTL_CLI_VERSION)"; then \
			echo "kubectl v$(KUBECTL_CLI_VERSION) is already installed."; \
		else \
			echo "Found kubectl version $$CURRENT_VERSION, installing v$(KUBECTL_CLI_VERSION)..."; \
			$(MAKE) download-and-install-kubectl-cli; \
		fi \
	else \
		$(MAKE) download-and-install-kubectl-cli; \
	fi

download-and-install-kubectl-cli:
	@echo "Installing kubectl v$(KUBECTL_CLI_VERSION)..."
	@echo "Detected OS: $(OS), Arch: $(KUBECTL_ARCH)"
	@echo "Downloading from $(KUBECTL_URL)..."
	@curl -L --progress-bar "$(KUBECTL_URL)" -o /tmp/kubectl
	@chmod +x /tmp/kubectl
	@echo "Moving to $(INSTALL_DIR)..."
	@sudo mv /tmp/kubectl $(INSTALL_DIR)/kubectl
	@echo "kubectl installed to $(INSTALL_DIR)/kubectl"
	@kubectl version --client
