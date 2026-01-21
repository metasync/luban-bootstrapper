# --- kp CLI variables ---
KP_OS := $(OS)
KP_ARCH := $(ARCH)

# kp uses 'amd64' for x86_64
ifeq ($(ARCH),x86_64)
	KP_ARCH := amd64
endif

KP_CLI_URL := https://github.com/buildpacks-community/kpack-cli/releases/download/v$(KP_CLI_VERSION)/kp-$(KP_OS)-$(KP_ARCH)-$(KP_CLI_VERSION)

.PHONY: install-kp-cli download-and-install-kp-cli

install-kp-cli:
	@if command -v kp >/dev/null 2>&1; then \
		CURRENT_VERSION=$$(kp version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1); \
		if echo "$$CURRENT_VERSION" | grep -q "^$(KP_CLI_VERSION)"; then \
			echo "kp CLI v$(KP_CLI_VERSION) is already installed."; \
		else \
			echo "Found kp version $$CURRENT_VERSION, installing v$(KP_CLI_VERSION)..."; \
			$(MAKE) download-and-install-kp-cli; \
		fi \
	else \
		$(MAKE) download-and-install-kp-cli; \
	fi

download-and-install-kp-cli:
	@echo "Installing kp CLI v$(KP_CLI_VERSION)..."
	@echo "Detected OS: $(KP_OS), Arch: $(KP_ARCH)"
	@echo "Downloading from $(KP_CLI_URL)..."
	@curl -L --progress-bar "$(KP_CLI_URL)" -o /tmp/kp
	@chmod +x /tmp/kp
	@echo "Installing to $(INSTALL_DIR)..."
	@sudo mv /tmp/kp $(INSTALL_DIR)/kp
	@echo "kp CLI installed to $(INSTALL_DIR)/kp"
	@kp version
