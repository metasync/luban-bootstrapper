include ../Makefile.env

# Argo Workflows installation and Gateway routing configuration.
# Installs Argo Workflows using the official Helm chart, configures RBAC for
# workflow execution, and exposes the UI via Envoy Gateway.

ARGO_REPO_URL ?= https://argoproj.github.io/argo-helm

.PHONY: install uninstall get-token

install:
	@echo "Adding Argo Helm repository..."
	@helm repo add argo $(ARGO_REPO_URL)
	@helm repo update argo
	@echo "Installing Argo Workflows (Chart v$(ARGO_WORKFLOWS_CHART_VERSION))..."
	# Disable built-in TLS (secure=false) to allow offloading TLS to Envoy Gateway.
	# The ServiceAccount 'workflow-runner' is configured as the default for workflows.
	@helm upgrade --install argo-workflows argo/argo-workflows \
		--namespace $(ARGO_WORKFLOWS_NAMESPACE) \
		--create-namespace \
		--version $(ARGO_WORKFLOWS_CHART_VERSION) \
		--set server.secure=false \
		--set server.extraArgs={--secure=false} \
		--set controller.workflowDefaults.spec.serviceAccountName=workflow-runner \
		--wait
	@echo "Applying workflow RBAC (ServiceAccount and RoleBinding)..."
	@$(KUBECTL) apply -n $(ARGO_WORKFLOWS_NAMESPACE) -f workflow-rbac.yaml
	@echo "Applying Gateway configuration..."
	@$(KUBECTL) apply -f gateway.yaml
	@POD=$$($(KUBECTL) -n $(ARGO_WORKFLOWS_NAMESPACE) get pod -l app.kubernetes.io/name=argo-workflows-server --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}'); \
	echo "Creating/updating argo-workflows-token secret in namespace $(ARGO_WORKFLOWS_NAMESPACE)"; \
	TOKEN=$$($(KUBECTL) -n $(ARGO_WORKFLOWS_NAMESPACE) exec $$POD -c argo-server -- argo auth token); \
	$(KUBECTL) -n $(ARGO_WORKFLOWS_NAMESPACE) create secret generic argo-workflows-token --from-literal=token="$$TOKEN" --dry-run=client -o yaml | $(KUBECTL) apply -f -

get-token:
	@echo "Retrieving token from secret argo-workflows-token..."
	@$(KUBECTL) -n $(ARGO_WORKFLOWS_NAMESPACE) get secret argo-workflows-token -o jsonpath='{.data.token}' | base64 -D
	@echo ""

uninstall:
	@echo "Uninstalling Gateway configuration..."
	@$(KUBECTL) delete -f gateway.yaml --ignore-not-found=true || true
	@echo "Uninstalling Argo Workflows..."
	@helm uninstall argo-workflows -n $(ARGO_WORKFLOWS_NAMESPACE) || true
	@echo "Deleting namespace $(ARGO_WORKFLOWS_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(ARGO_WORKFLOWS_NAMESPACE) --ignore-not-found=true || true
