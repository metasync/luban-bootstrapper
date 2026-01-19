include ../Makefile.env

# kpack installation for image building.
# kpack does not have an official Helm chart, so we install it via raw manifests
# from the release page.

KPACK_RELEASE_URL ?= https://github.com/buildpacks-community/kpack/releases/download/v$(KPACK_VERSION)/release-$(KPACK_VERSION).yaml

.PHONY: install uninstall

install:
	@echo "Installing kpack v$(KPACK_VERSION)..."
	@retries=5; \
	for i in $$(seq 1 $$retries); do \
	  if $(KUBECTL) apply -f $(KPACK_RELEASE_URL) >/dev/null 2>&1; then \
	    break; \
	  fi; \
	  if [ $$i -eq $$retries ]; then \
	    echo "kpack apply failed after $$retries attempts"; \
	    exit 1; \
	  fi; \
	  echo "kpack apply failed (attempt $$i of $$retries), retrying in 10s..."; \
	  sleep 10; \
	done
	@echo "Waiting for kpack-controller to be ready..."
	@$(KUBECTL) wait -n $(KPACK_NAMESPACE) deployment/kpack-controller --for=condition=Available --timeout=5m

uninstall:
	@echo "Uninstalling kpack..."
	@$(KUBECTL) delete -f $(KPACK_RELEASE_URL) || true
	@echo "Deleting namespace $(KPACK_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(KPACK_NAMESPACE) --ignore-not-found=true || true
