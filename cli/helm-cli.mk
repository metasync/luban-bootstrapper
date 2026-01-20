# --- Helm CLI variables ---
# helm uses 'darwin'/'linux' and 'amd64'/'arm64'
HELM_ARCH := $(ARCH)

ifeq ($(ARCH),x86_64)
	HELM_ARCH := amd64
endif
ifneq ($(filter arm64 aarch64,$(ARCH)),)
	HELM_ARCH := arm64
endif

HELM_URL := https://get.helm.sh/helm-v$(HELM_CLI_VERSION)-$(OS)-$(HELM_ARCH).tar.gz

.PHONY: install-helm-cli download-and-install-helm-cli

install-helm-cli:
	@if command -v helm >/dev/null 2>&1; then \
		CURRENT_VERSION=$$(helm version --short | cut -d+ -f1 | tr -d 'v'); \
		if echo "$$CURRENT_VERSION" | grep -q "^$(HELM_CLI_VERSION)"; then \
			echo "helm v$(HELM_CLI_VERSION) is already installed."; \
		else \
			echo "Found helm version $$CURRENT_VERSION, installing v$(HELM_CLI_VERSION)..."; \
			$(MAKE) download-and-install-helm-cli; \
		fi \
	else \
		$(MAKE) download-and-install-helm-cli; \
	fi

download-and-install-helm-cli:
	@echo "Installing Helm v$(HELM_CLI_VERSION)..."
	@echo "Detected OS: $(OS), Arch: $(HELM_ARCH)"
	@echo "Downloading from $(HELM_URL)..."
	@curl -L --progress-bar "$(HELM_URL)" -o /tmp/helm.tar.gz
	@echo "Extracting to $(INSTALL_DIR)..."
	@tar -zxvf /tmp/helm.tar.gz -C /tmp $(OS)-$(HELM_ARCH)/helm
	@sudo mv /tmp/$(OS)-$(HELM_ARCH)/helm $(INSTALL_DIR)/helm
	@rm -rf /tmp/helm.tar.gz /tmp/$(OS)-$(HELM_ARCH)
	@echo "Helm installed to $(INSTALL_DIR)/helm"
	@helm version --short
