include ../Makefile.env

# Gateway namespace, local CA and Envoy Gateway resources.
# This Makefile manages the core Gateway API resources, including the GatewayClass,
# Gateway, and a local Certificate Authority (CA) for issuing TLS certificates.

.PHONY: install uninstall create-secret

create-secret:
	@if [ -f ../secrets/cloudflare.env ]; then \
		echo "Creating Cloudflare API token secret..."; \
		export $$(cat ../secrets/cloudflare.env | xargs) && \
		$(KUBECTL) create secret generic cloudflare-api-token-secret \
			-n $(GATEWAY_NAMESPACE) \
			--from-literal=api-token=$$CLOUDFLARE_API_TOKEN \
			--dry-run=client -o yaml | $(KUBECTL) apply -f -; \
	else \
		echo "Warning: ../secrets/cloudflare.env not found. Skipping Cloudflare secret creation."; \
	fi

install:
	@echo "Ensuring cert-manager webhook is available before applying gateway resources..."
	@$(KUBECTL) wait -n $(CERT_MANAGER_NAMESPACE) deployment/cert-manager-webhook --for=condition=Available --timeout=5m
	@echo "Applying gateway resources..."
	@$(KUBECTL) apply -f gateway.yaml
	@echo "Creating Cloudflare secret..."
	@$(MAKE) create-secret
	@echo "Applying local ingress resources..."
	@$(KUBECTL) apply -f local-ingress.yaml
	@echo "Applying public ingress resources..."
	@$(KUBECTL) apply -f public-ingress.yaml

uninstall:
	@echo "Uninstalling gateway resources..."
	-@$(KUBECTL) delete -f public-ingress.yaml || true
	-@$(KUBECTL) delete -f local-ingress.yaml || true
	-@$(KUBECTL) delete -f gateway.yaml || true
	-@$(KUBECTL) delete secret cloudflare-api-token-secret -n $(GATEWAY_NAMESPACE) || true
	-@$(KUBECTL) delete gateways.gateway.networking.k8s.io luban-gateway -n $(GATEWAY_NAMESPACE) || true
	-@$(KUBECTL) delete gatewayclasses.gateway.networking.k8s.io envoy || true
	-@$(KUBECTL) delete issuers.cert-manager.io local-ca-issuer -n $(GATEWAY_NAMESPACE) || true
	-@$(KUBECTL) delete certificates.cert-manager.io local-ca -n $(GATEWAY_NAMESPACE) || true
	-@$(KUBECTL) delete issuers.cert-manager.io local-selfsigned -n $(GATEWAY_NAMESPACE) || true
	@echo "Deleting namespace $(GATEWAY_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(GATEWAY_NAMESPACE) --ignore-not-found=true || true
