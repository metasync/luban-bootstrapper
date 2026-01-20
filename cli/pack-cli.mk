# --- Pack CLI variables ---
# pack uses 'macos' instead of 'darwin'
# pack uses 'arm64' suffix for ARM, empty suffix for AMD64
PACK_OS := $(OS)
PACK_ARCH_SUFFIX :=

ifeq ($(OS),darwin)
	PACK_OS := macos
endif

ifneq ($(ARCH),x86_64)
	ifneq ($(filter arm64 aarch64,$(ARCH)),)
		PACK_ARCH_SUFFIX := -arm64
	endif
endif

PACK_CLI_URL := https://github.com/buildpacks/pack/releases/download/v$(PACK_CLI_VERSION)/pack-v$(PACK_CLI_VERSION)-$(PACK_OS)$(PACK_ARCH_SUFFIX).tgz

.PHONY: install-pack-cli download-and-install-pack-cli

install-pack-cli:
	@if command -v pack >/dev/null 2>&1; then \
		CURRENT_VERSION=$$(pack version | cut -d ' ' -f 1 | tr -d 'v'); \
		if echo "$$CURRENT_VERSION" | grep -q "^$(PACK_CLI_VERSION)"; then \
			echo "pack CLI v$(PACK_CLI_VERSION) is already installed."; \
		else \
			echo "Found pack version $$CURRENT_VERSION, installing v$(PACK_CLI_VERSION)..."; \
			$(MAKE) download-and-install-pack-cli; \
		fi \
	else \
		$(MAKE) download-and-install-pack-cli; \
	fi

download-and-install-pack-cli:
	@echo "Installing pack CLI v$(PACK_CLI_VERSION)..."
	@echo "Detected OS: $(PACK_OS), Arch: $(ARCH)"
	@echo "Downloading from $(PACK_CLI_URL)..."
	@curl -L --progress-bar "$(PACK_CLI_URL)" -o /tmp/pack.tgz
	@echo "Extracting to $(INSTALL_DIR)..."
	@sudo tar -C $(INSTALL_DIR) --no-same-owner -xzvf /tmp/pack.tgz pack
	@rm /tmp/pack.tgz
	@echo "pack CLI installed to $(INSTALL_DIR)/pack"
	@pack version
