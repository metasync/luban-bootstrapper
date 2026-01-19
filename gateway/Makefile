include ../Makefile.env

# Gateway namespace, local CA and Envoy Gateway resources.
# This Makefile manages the core Gateway API resources, including the GatewayClass,
# Gateway, and a local Certificate Authority (CA) for issuing TLS certificates.

.PHONY: install uninstall

install:
	@echo "Ensuring cert-manager webhook is available before applying gateway resources..."
	@$(KUBECTL) wait -n $(CERT_MANAGER_NAMESPACE) deployment/cert-manager-webhook --for=condition=Available --timeout=5m
	@echo "Applying gateway resources..."
	@$(KUBECTL) apply -f resources.yaml

uninstall:
	@echo "Uninstalling gateway resources..."
	-@$(KUBECTL) delete -f resources.yaml || true
	-@$(KUBECTL) delete gateways.gateway.networking.k8s.io argo-gateway -n $(GATEWAY_NAMESPACE) || true
	-@$(KUBECTL) delete gatewayclasses.gateway.networking.k8s.io envoy || true
	-@$(KUBECTL) delete issuers.cert-manager.io local-ca-issuer -n $(GATEWAY_NAMESPACE) || true
	-@$(KUBECTL) delete certificates.cert-manager.io local-ca -n $(GATEWAY_NAMESPACE) || true
	-@$(KUBECTL) delete issuers.cert-manager.io local-selfsigned -n $(GATEWAY_NAMESPACE) || true
	@echo "Deleting namespace $(GATEWAY_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(GATEWAY_NAMESPACE) --ignore-not-found=true || true
