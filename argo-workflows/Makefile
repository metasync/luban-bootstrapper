include ../Makefile.env

# Argo Workflows installation and Gateway routing configuration.

.PHONY: install uninstall get-token

install:
	@echo "Creating namespace $(ARGO_WORKFLOWS_NAMESPACE)..."
	@$(KUBECTL) create namespace $(ARGO_WORKFLOWS_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@echo "Installing Argo Workflows v$(ARGO_WORKFLOWS_VERSION)..."
	@$(KUBECTL) apply -n $(ARGO_WORKFLOWS_NAMESPACE) -f https://github.com/argoproj/argo-workflows/releases/download/v$(ARGO_WORKFLOWS_VERSION)/install.yaml
	@echo "Patching Argo Server configuration..."
	@$(KUBECTL) patch deployment argo-server -n $(ARGO_WORKFLOWS_NAMESPACE) --type=json \
	  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--secure=false"},\
		{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/scheme","value":"HTTP"}]' || true
	@echo "Waiting for deployments to be ready..."
	@$(KUBECTL) wait -n $(ARGO_WORKFLOWS_NAMESPACE) deployment/argo-server --for=condition=Available --timeout=5m
	@$(KUBECTL) wait -n $(ARGO_WORKFLOWS_NAMESPACE) deployment/workflow-controller --for=condition=Available --timeout=5m
	@echo "Applying workflow RBAC (ServiceAccount and RoleBinding)..."
	@$(KUBECTL) apply -n $(ARGO_WORKFLOWS_NAMESPACE) -f workflow-rbac.yaml
	@echo "Configuring default workflow service account..."
	@$(KUBECTL) -n $(ARGO_WORKFLOWS_NAMESPACE) patch configmap workflow-controller-configmap --type=merge -p '{"data":{"workflowDefaults":"spec:\n  serviceAccountName: workflow-runner"}}'
	@echo "Applying Gateway configuration..."
	@$(KUBECTL) apply -f gateway.yaml
	@POD=$$($(KUBECTL) -n $(ARGO_WORKFLOWS_NAMESPACE) get pod -l app=argo-server --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}'); \
	echo "Creating/updating argo-workflows-token secret in namespace $(ARGO_WORKFLOWS_NAMESPACE)"; \
	TOKEN=$$($(KUBECTL) -n $(ARGO_WORKFLOWS_NAMESPACE) exec $$POD -c argo-server -- argo auth token); \
	$(KUBECTL) -n $(ARGO_WORKFLOWS_NAMESPACE) create secret generic argo-workflows-token --from-literal=token="$$TOKEN" --dry-run=client -o yaml | $(KUBECTL) apply -f -

get-token:
	@echo "Retrieving token from secret argo-workflows-token..."
	@$(KUBECTL) -n $(ARGO_WORKFLOWS_NAMESPACE) get secret argo-workflows-token -o jsonpath='{.data.token}' | base64 -D
	@echo ""

uninstall:
	@echo "Uninstalling Gateway configuration..."
	@$(KUBECTL) delete -f gateway.yaml || true
	@echo "Uninstalling Argo Workflows..."
	@$(KUBECTL) delete -n $(ARGO_WORKFLOWS_NAMESPACE) -f https://github.com/argoproj/argo-workflows/releases/download/v$(ARGO_WORKFLOWS_VERSION)/install.yaml || true
	@echo "Deleting namespace $(ARGO_WORKFLOWS_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(ARGO_WORKFLOWS_NAMESPACE) --ignore-not-found=true || true
