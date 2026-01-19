include ../Makefile.env

# Argo CD installation and Gateway routing configuration.

ARGO_CD_MANIFEST_URL ?= https://raw.githubusercontent.com/argoproj/argo-cd/v$(ARGO_CD_VERSION)/manifests/install.yaml

.PHONY: install uninstall

install:
	@echo "Creating namespace $(ARGO_CD_NAMESPACE)..."
	@$(KUBECTL) create namespace $(ARGO_CD_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@echo "Installing Argo CD v$(ARGO_CD_VERSION)..."
	@$(KUBECTL) apply -n $(ARGO_CD_NAMESPACE) -f $(ARGO_CD_MANIFEST_URL)
	@echo "Patching Argo CD Server configuration..."
	@$(KUBECTL) patch deployment argocd-server -n $(ARGO_CD_NAMESPACE) --type=json \
	  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"},\
		{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/scheme","value":"HTTP"},\
		{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/httpGet/scheme","value":"HTTP"}]' || true
	@echo "Waiting for Argo CD Server to be ready..."
	@$(KUBECTL) wait -n $(ARGO_CD_NAMESPACE) deployment/argocd-server --for=condition=Available --timeout=5m
	@echo "Applying Gateway configuration..."
	@$(KUBECTL) apply -f gateway.yaml

uninstall:
	@echo "Uninstalling Gateway configuration..."
	@$(KUBECTL) delete -f gateway.yaml || true
	@echo "Uninstalling Argo CD..."
	@$(KUBECTL) delete -n $(ARGO_CD_NAMESPACE) -f $(ARGO_CD_MANIFEST_URL) || true
	@echo "Deleting namespace $(ARGO_CD_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(ARGO_CD_NAMESPACE) --ignore-not-found=true || true
