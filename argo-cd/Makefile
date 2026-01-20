include ../Makefile.env

# Argo CD installation and Gateway routing configuration.
# Installs Argo CD using the official Helm chart and configures an HTTPS
# route via Envoy Gateway.

ARGO_REPO_URL ?= https://argoproj.github.io/argo-helm

.PHONY: install uninstall

install:
	@echo "Adding Argo Helm repository..."
	@helm repo add argo $(ARGO_REPO_URL)
	@helm repo update argo
	@echo "Installing Argo CD (Chart v$(ARGO_CD_CHART_VERSION))..."
	# Insecure mode is required because TLS is terminated at the Gateway.
	# The Gateway communicates with Argo CD via HTTP.
	@helm upgrade --install argo-cd argo/argo-cd \
		--namespace $(ARGO_CD_NAMESPACE) \
		--create-namespace \
		--version $(ARGO_CD_CHART_VERSION) \
		--set server.extraArgs={--insecure} \
		--set server.readinessProbe.httpGet.scheme=HTTP \
		--set server.livenessProbe.httpGet.scheme=HTTP \
		--wait
	@echo "Applying Gateway configuration..."
	@$(KUBECTL) apply -f gateway.yaml

get-password:
	@echo "Retrieving initial admin password from secret argocd-initial-admin-secret..."
	@$(KUBECTL) -n $(ARGO_CD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -D
	@echo ""

uninstall:
	@echo "Uninstalling Gateway configuration..."
	@$(KUBECTL) delete -f gateway.yaml --ignore-not-found=true || true
	@echo "Uninstalling Argo CD..."
	@helm uninstall argo-cd -n $(ARGO_CD_NAMESPACE) || true
	@echo "Deleting namespace $(ARGO_CD_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(ARGO_CD_NAMESPACE) --ignore-not-found=true || true
