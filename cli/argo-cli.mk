# --- argo CLI variables ---
ARGO_OS := $(OS)
ARGO_ARCH := $(ARCH)

# Argo uses 'amd64' for x86_64
ifeq ($(ARCH),x86_64)
	ARGO_ARCH := amd64
endif

ARGO_CLI_URL := https://github.com/argoproj/argo-workflows/releases/download/v$(ARGO_CLI_VERSION)/argo-$(ARGO_OS)-$(ARGO_ARCH).gz

.PHONY: install-argo-cli download-and-install-argo-cli

install-argo-cli:
	@if command -v argo >/dev/null 2>&1; then \
		CURRENT_VERSION=$$(argo version --short | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n1); \
		if [ "$$CURRENT_VERSION" = "v$(ARGO_CLI_VERSION)" ]; then \
			echo "argo CLI v$(ARGO_CLI_VERSION) is already installed."; \
		else \
			echo "Found argo version $$CURRENT_VERSION, installing v$(ARGO_CLI_VERSION)..."; \
			$(MAKE) download-and-install-argo-cli; \
		fi \
	else \
		$(MAKE) download-and-install-argo-cli; \
	fi

download-and-install-argo-cli:
	@echo "Installing argo CLI v$(ARGO_CLI_VERSION)..."
	@echo "Detected OS: $(ARGO_OS), Arch: $(ARGO_ARCH)"
	@echo "Downloading from $(ARGO_CLI_URL)..."
	@curl -L --progress-bar "$(ARGO_CLI_URL)" -o /tmp/argo.gz
	@gunzip -f /tmp/argo.gz
	@chmod +x /tmp/argo
	@echo "Installing to $(INSTALL_DIR)..."
	@sudo mv /tmp/argo $(INSTALL_DIR)/argo
	@echo "argo CLI installed to $(INSTALL_DIR)/argo"
	@argo version --short
