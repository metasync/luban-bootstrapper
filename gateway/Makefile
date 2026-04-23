include ../Makefile.env

# Gateway namespace, local CA and Envoy Gateway resources.
# This Makefile manages the core Gateway API resources, including the GatewayClass,
# Gateway, and a local Certificate Authority (CA) for issuing TLS certificates.

.PHONY: install uninstall create-secret

create-secret:
	@if [ -f ../secrets/cloudflare.env ]; then \
		set -a; . ../secrets/cloudflare.env; set +a; \
		if [ -z "$$CLOUDFLARE_API_TOKEN" ]; then \
			echo "Warning: CLOUDFLARE_API_TOKEN is empty. Skipping Cloudflare secret creation."; \
			exit 0; \
		fi; \
		echo "Creating Cloudflare API token secret..."; \
		$(KUBECTL) create secret generic cloudflare-api-token-secret \
			-n $(GATEWAY_NAMESPACE) \
			--from-literal=api-token="$$CLOUDFLARE_API_TOKEN" \
			--dry-run=client -o yaml | $(KUBECTL) apply -f -; \
	else \
		echo "Warning: ../secrets/cloudflare.env not found. Skipping Cloudflare secret creation."; \
	fi

install:
	@if [ "$(FORCE)" != "1" ] && $(KUBECTL) -n $(GATEWAY_NAMESPACE) get gateway luban-gateway >/dev/null 2>&1; then \
		echo "gateway already installed (set FORCE=1 to re-apply)"; \
	else \
		echo "Ensuring cert-manager webhook is available before applying gateway resources..."; \
		$(KUBECTL) wait -n $(CERT_MANAGER_NAMESPACE) deployment/cert-manager-webhook --for=condition=Available --timeout=5m; \
		echo "Applying gateway resources..."; \
		export GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
			K8S_DOMAIN=$(K8S_DOMAIN) \
			LUBAN_PUBLIC_DOMAIN=$(LUBAN_PUBLIC_DOMAIN) \
			APPS_DOMAIN=$(APPS_DOMAIN) \
			APPS_PUBLIC_DOMAIN=$(APPS_PUBLIC_DOMAIN) && \
			envsubst < gateway.yaml | $(KUBECTL) apply -f -; \
		echo "Creating Cloudflare secret..."; \
		$(MAKE) create-secret; \
		echo "Applying local ingress resources..."; \
		export GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
			K8S_DOMAIN=$(K8S_DOMAIN) \
			APPS_DOMAIN=$(APPS_DOMAIN) && \
			envsubst < local-ingress.yaml | $(KUBECTL) apply -f -; \
		echo "Applying public ingress resources..."; \
		export GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
			LETSENCRYPT_EMAIL=$(LETSENCRYPT_EMAIL) \
			LUBAN_PUBLIC_DOMAIN=$(LUBAN_PUBLIC_DOMAIN) \
			APPS_PUBLIC_DOMAIN=$(APPS_PUBLIC_DOMAIN) && \
			envsubst < public-ingress.yaml | $(KUBECTL) apply -f -; \
	fi

uninstall:
	@echo "Uninstalling gateway resources..."
	-@export GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		LETSENCRYPT_EMAIL=$(LETSENCRYPT_EMAIL) \
		LUBAN_PUBLIC_DOMAIN=$(LUBAN_PUBLIC_DOMAIN) \
		APPS_PUBLIC_DOMAIN=$(APPS_PUBLIC_DOMAIN) && \
		envsubst < public-ingress.yaml | $(KUBECTL) delete -f - || true
	-@export GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		K8S_DOMAIN=$(K8S_DOMAIN) \
		APPS_DOMAIN=$(APPS_DOMAIN) && \
		envsubst < local-ingress.yaml | $(KUBECTL) delete -f - || true
	-@export GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		K8S_DOMAIN=$(K8S_DOMAIN) \
		LUBAN_PUBLIC_DOMAIN=$(LUBAN_PUBLIC_DOMAIN) \
		APPS_DOMAIN=$(APPS_DOMAIN) \
		APPS_PUBLIC_DOMAIN=$(APPS_PUBLIC_DOMAIN) && \
		envsubst < gateway.yaml | $(KUBECTL) delete -f - || true
	-@$(KUBECTL) delete secret cloudflare-api-token-secret -n $(GATEWAY_NAMESPACE) || true
	@echo "Deleting namespace $(GATEWAY_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(GATEWAY_NAMESPACE) --ignore-not-found=true || true
