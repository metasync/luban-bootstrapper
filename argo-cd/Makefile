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
		--set server.readinessProbe.timeoutSeconds=5 \
		--set server.readinessProbe.failureThreshold=6 \
		--set server.livenessProbe.httpGet.scheme=HTTP \
		--set server.livenessProbe.timeoutSeconds=5 \
		--set server.livenessProbe.failureThreshold=6 \
		--set repoServer.readinessProbe.timeoutSeconds=5 \
		--set repoServer.readinessProbe.failureThreshold=6 \
		--set repoServer.livenessProbe.timeoutSeconds=5 \
		--set repoServer.livenessProbe.failureThreshold=6 \
		--wait
	@echo "Applying Gateway configuration..."
	@export ARGO_CD_NAMESPACE=$(ARGO_CD_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		ARGO_CD_HOST=$(ARGO_CD_HOST) \
		ARGO_CD_PUBLIC_HOST=$(ARGO_CD_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) apply -f -

get-init-secret:
	@echo "Retrieving initial admin password from secret argocd-initial-admin-secret..."
	@$(KUBECTL) -n $(ARGO_CD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | $(BASE64_DECODE)
	@echo ""

change-password:
	@echo "Changing Argo CD admin password..."
	@printf "Enter new admin password: "; \
	read -s PASSWORD; \
	echo ""; \
	printf "Confirm new admin password: "; \
	read -s PASSWORD_CONFIRM; \
	echo ""; \
	if [ "$$PASSWORD" != "$$PASSWORD_CONFIRM" ]; then \
		echo "Passwords do not match."; \
		exit 1; \
	fi; \
	HASH=$$(htpasswd -B -b -n -C 10 admin "$$PASSWORD" | cut -d ":" -f 2 | tr -d '\n'); \
	TIME=$$(date -u +%FT%T%Z | tr -d '\n'); \
	$(KUBECTL) -n $(ARGO_CD_NAMESPACE) patch secret argocd-secret \
		-p "{\"data\": {\"admin.password\": \"$$(printf "%s" "$$HASH" | base64 | tr -d '\n')\", \"admin.passwordMtime\": \"$$(printf "%s" "$$TIME" | base64 | tr -d '\n')\"}}"; \
	echo "Restarting Argo CD server to apply changes..."; \
	$(KUBECTL) -n $(ARGO_CD_NAMESPACE) rollout restart deployment argo-cd-argocd-server; \
	echo "Admin password updated successfully. Please wait for the server to restart."

uninstall:
	@echo "Uninstalling Gateway configuration..."
	@export ARGO_CD_NAMESPACE=$(ARGO_CD_NAMESPACE) \
		GATEWAY_NAMESPACE=$(GATEWAY_NAMESPACE) \
		ARGO_CD_HOST=$(ARGO_CD_HOST) \
		ARGO_CD_PUBLIC_HOST=$(ARGO_CD_PUBLIC_HOST) && \
		envsubst < gateway.yaml | $(KUBECTL) delete -f - --ignore-not-found=true || true
	@echo "Uninstalling Argo CD..."
	@helm uninstall argo-cd -n $(ARGO_CD_NAMESPACE) || true
	@echo "Deleting namespace $(ARGO_CD_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(ARGO_CD_NAMESPACE) --ignore-not-found=true || true
