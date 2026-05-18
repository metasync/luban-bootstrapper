include ../Makefile.env

# Harbor installation and Gateway routing configuration.
# Installs Harbor using the official Helm chart and configures an HTTPS
# route via Envoy Gateway.

HARBOR_REPO_URL ?= https://helm.goharbor.io

.PHONY: install uninstall

install:
	@echo "Adding Harbor Helm repository..."
	@helm repo add harbor $(HARBOR_REPO_URL)
	@helm repo update harbor
	@echo "Installing Harbor (Chart v$(HARBOR_CHART_VERSION))..."
	@helm upgrade --install harbor harbor/harbor \
		--namespace $(HARBOR_NAMESPACE) \
		--create-namespace \
		--version $(HARBOR_CHART_VERSION) \
		--values values.yaml \
		--set externalURL=https://$(HARBOR_HOST) \
		--set expose.type=clusterIP \
		--set expose.tls.enabled=false \
		--set persistence.enabled=true \
		--timeout 10m \
		--wait
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) patch deployment harbor-core --type='json' \
		--patch-file probes-single-container.jsonpatch.yaml >/dev/null
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) patch deployment harbor-jobservice --type='json' \
		--patch-file probes-single-container.jsonpatch.yaml >/dev/null
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) patch deployment harbor-nginx --type='json' \
		--patch-file probes-single-container.jsonpatch.yaml >/dev/null
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) patch deployment harbor-portal --type='json' \
		--patch-file probes-single-container.jsonpatch.yaml >/dev/null
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) patch deployment harbor-registry --type='json' \
		--patch-file probes-registry.jsonpatch.yaml >/dev/null
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) patch statefulset harbor-database --type='json' \
		--patch-file probes-database.jsonpatch.yaml >/dev/null
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) patch statefulset harbor-redis --type='json' \
		--patch-file probes-redis.jsonpatch.yaml >/dev/null
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) rollout status deployment/harbor-core --timeout=600s
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) rollout status deployment/harbor-jobservice --timeout=600s
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) rollout status deployment/harbor-nginx --timeout=600s
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) rollout status deployment/harbor-portal --timeout=600s
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) rollout status deployment/harbor-registry --timeout=600s
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) rollout status statefulset/harbor-database --timeout=600s
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) rollout status statefulset/harbor-redis --timeout=600s
	@echo "Applying Gateway configuration..."
	@export HARBOR_NAMESPACE=$(HARBOR_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		HARBOR_HOST=$(HARBOR_HOST) \
		HARBOR_PUBLIC_HOST=$(HARBOR_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) apply -f -

get-password:
	@echo "Retrieving Harbor admin password..."
	@$(KUBECTL) -n $(HARBOR_NAMESPACE) get secret harbor-core -o jsonpath='{.data.HARBOR_ADMIN_PASSWORD}' | $(BASE64_DECODE)
	@echo ""

uninstall:
	@echo "Uninstalling Gateway configuration..."
	@export HARBOR_NAMESPACE=$(HARBOR_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		HARBOR_HOST=$(HARBOR_HOST) \
		HARBOR_PUBLIC_HOST=$(HARBOR_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) delete -f - --ignore-not-found=true || true
	@echo "Uninstalling Harbor..."
	@helm uninstall harbor -n $(HARBOR_NAMESPACE) || true
	@echo "Deleting namespace $(HARBOR_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(HARBOR_NAMESPACE) --ignore-not-found=true || true
