include Makefile.env

# ANSI Color Codes
CYAN := \033[36m
YELLOW := \033[33m
BOLD := \033[1m
RESET := \033[0m

# Root orchestration Makefile.
# Installs shared infrastructure first (cert-manager, Envoy Gateway, Gateway)
# and then application components (Argo Workflows, Argo CD, Argo Events, kpack).
# Also provides targets to install necessary CLIs (pack, helm, kubectl).

.PHONY: help all \
	cert-manager reflector envoy-gateway gateway \
	argo-workflows argo-cd argo-events kpack harbor jupyterhub \
	cli pack-cli kp-cli helm-cli kubectl-cli argo-cli \
	uninstall \
	uninstall-cert-manager uninstall-reflector uninstall-envoy-gateway uninstall-gateway \
	uninstall-argo-workflows uninstall-argo-cd uninstall-argo-events uninstall-kpack uninstall-harbor uninstall-jupyterhub

help:
	@echo "$(BOLD)Usage:$(RESET)"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make all" "Install infra and all components"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make cert-manager" "Install cert-manager (Chart $(CERT_MANAGER_CHART_VERSION))"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make reflector" "Install Reflector (Chart $(REFLECTOR_CHART_VERSION))"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make envoy-gateway" "Install Envoy Gateway (Chart $(ENVOY_GATEWAY_CHART_VERSION))"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make gateway" "Install Gateway API config and local CA issuer"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make argo-workflows" "Install Argo Workflows (Chart $(ARGO_WORKFLOWS_CHART_VERSION)) into namespace $(ARGO_WORKFLOWS_NAMESPACE)"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make argo-cd" "Install Argo CD (Chart $(ARGO_CD_CHART_VERSION)) into namespace $(ARGO_CD_NAMESPACE)"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make argo-events" "Install Argo Events (Chart $(ARGO_EVENTS_CHART_VERSION)) into namespace $(ARGO_EVENTS_NAMESPACE)"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make kpack" "Install kpack ($(KPACK_VERSION))"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make harbor" "Install Harbor (Chart $(HARBOR_CHART_VERSION))"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make jupyterhub" "Install JupyterHub (Chart $(JUPYTERHUB_CHART_VERSION))"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make pack-cli" "Install pack CLI (v$(PACK_CLI_VERSION))"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make kp-cli" "Install kp CLI (v$(KP_CLI_VERSION))"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make helm-cli" "Install Helm CLI (v$(HELM_CLI_VERSION))"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make kubectl-cli" "Install Kubectl CLI (v$(KUBECTL_CLI_VERSION))"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make argo-cli" "Install Argo CLI (v$(ARGO_CLI_VERSION))"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make cli" "Install all CLIs (pack, kp, helm, kubectl, argo)"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make uninstall" "Uninstall all components and infra"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make uninstall-cert-manager" "Uninstall cert-manager"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make uninstall-reflector" "Uninstall Reflector"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make uninstall-envoy-gateway" "Uninstall Envoy Gateway"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make uninstall-gateway" "Uninstall Gateway API config and local CA issuer"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make uninstall-argo-workflows" "Uninstall Argo Workflows"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make uninstall-argo-cd" "Uninstall Argo CD"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make uninstall-argo-events" "Uninstall Argo Events"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make uninstall-kpack" "Uninstall kpack"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make uninstall-harbor" "Uninstall Harbor"
	@printf "  $(CYAN)%-35s$(RESET) %s\n" "make uninstall-jupyterhub" "Uninstall JupyterHub"
	@echo ""
	@echo "$(BOLD)Environment variables (from Makefile.env):$(RESET)"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "KUBECTL" "kubectl binary to use"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "ARGO_WORKFLOWS_CHART_VERSION" "Argo Workflows chart version"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "ARGO_CD_CHART_VERSION" "Argo CD chart version"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "ARGO_EVENTS_CHART_VERSION" "Argo Events chart version"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "KPACK_VERSION" "kpack version tag"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "PACK_CLI_VERSION" "pack CLI version"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "HELM_CLI_VERSION" "Helm CLI version"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "KUBECTL_CLI_VERSION" "Kubectl CLI version"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "ARGO_CLI_VERSION" "Argo CLI version"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "ARGO_WORKFLOWS_NAMESPACE" "Namespace for Argo Workflows"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "ARGO_CD_NAMESPACE" "Namespace for Argo CD"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "ARGO_EVENTS_NAMESPACE" "Namespace for Argo Events"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "KPACK_NAMESPACE" "Namespace for kpack"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "HARBOR_NAMESPACE" "Namespace for Harbor"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "ENVOY_GATEWAY_NAMESPACE" "Namespace for Envoy Gateway"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "CERT_MANAGER_NAMESPACE" "Namespace for cert-manager"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "REFLECTOR_NAMESPACE" "Namespace for Reflector"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "GATEWAY_NAMESPACE" "Namespace for Gateway resources"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "ENVOY_GATEWAY_CHART_VERSION" "Envoy Gateway chart version"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "CERT_MANAGER_CHART_VERSION" "cert-manager chart version"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "REFLECTOR_CHART_VERSION" "Reflector chart version"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "HARBOR_CHART_VERSION" "Harbor chart version"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "K8S_DOMAIN" "Base domain for ingress hosts"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "ARGO_WORKFLOWS_HOST" "Hostname for Argo Workflows UI"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "ARGO_CD_HOST" "Hostname for Argo CD UI"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "HARBOR_HOST" "Hostname for Harbor UI"
	@printf "  $(YELLOW)%-35s$(RESET) %s\n" "JUPYTERHUB_HOST" "Hostname for JupyterHub UI"

all: cert-manager \
	reflector \
	envoy-gateway \
	gateway \
	argo-workflows \
	argo-cd \
	argo-events \
	kpack \
	harbor

cert-manager:
	@echo "=== Installing cert-manager ==="
	@$(MAKE) -C cert-manager install

reflector:
	@echo "=== Installing Reflector ==="
	@$(MAKE) -C reflector install

envoy-gateway:
	@echo "=== Installing Envoy Gateway ==="
	@$(MAKE) -C envoy-gateway install

gateway:
	@echo "=== Installing Gateway configuration ==="
	@$(MAKE) -C gateway install

argo-workflows:
	@echo "=== Installing Argo Workflows ==="
	@$(MAKE) -C argo-workflows install

argo-cd:
	@echo "=== Installing Argo CD ==="
	@$(MAKE) -C argo-cd install

argo-events:
	@echo "=== Installing Argo Events ==="
	@$(MAKE) -C argo-events install

kpack:
	@echo "=== Installing kpack ==="
	@$(MAKE) -C kpack install

harbor:
	@echo "=== Installing Harbor ==="
	@$(MAKE) -C harbor install

jupyterhub:
	@echo "=== Installing JupyterHub ==="
	@$(MAKE) -C jupyterhub install

cli:
	@echo "=== Installing all CLIs ==="
	@$(MAKE) -C cli install-all-cli

pack-cli:
	@echo "=== Installing pack CLI ==="
	@$(MAKE) -C cli install-pack-cli

kp-cli:
	@echo "=== Installing kp CLI ==="
	@$(MAKE) -C cli install-kp-cli

helm-cli:
	@echo "=== Installing Helm CLI ==="
	@$(MAKE) -C cli install-helm-cli

kubectl-cli:
	@echo "=== Installing Kubectl CLI ==="
	@$(MAKE) -C cli install-kubectl-cli

argo-cli:
	@echo "=== Installing Argo CLI ==="
	@$(MAKE) -C cli install-argo-cli

uninstall: uninstall-argo-workflows \
	uninstall-argo-cd \
	uninstall-argo-events \
	uninstall-kpack \
	uninstall-harbor \
	uninstall-jupyterhub \
	uninstall-gateway \
	uninstall-envoy-gateway \
	uninstall-reflector \
	uninstall-cert-manager

uninstall-harbor:
	@echo "=== Uninstalling Harbor ==="
	@$(MAKE) -C harbor uninstall

uninstall-jupyterhub:
	@echo "=== Uninstalling JupyterHub ==="
	@$(MAKE) -C jupyterhub uninstall

uninstall-cert-manager:
	@echo "=== Uninstalling cert-manager ==="
	@$(MAKE) -C cert-manager uninstall

uninstall-reflector:
	@echo "=== Uninstalling Reflector ==="
	@$(MAKE) -C reflector uninstall

uninstall-envoy-gateway:
	@echo "=== Uninstalling Envoy Gateway ==="
	@$(MAKE) -C envoy-gateway uninstall

uninstall-gateway:
	@echo "=== Uninstalling Gateway configuration ==="
	@$(MAKE) -C gateway uninstall

uninstall-argo-workflows:
	@echo "=== Uninstalling Argo Workflows ==="
	@$(MAKE) -C argo-workflows uninstall

uninstall-argo-cd:
	@echo "=== Uninstalling Argo CD ==="
	@$(MAKE) -C argo-cd uninstall

uninstall-argo-events:
	@echo "=== Uninstalling Argo Events ==="
	@$(MAKE) -C argo-events uninstall

uninstall-kpack:
	@echo "=== Uninstalling kpack ==="
	@$(MAKE) -C kpack uninstall

prune:
	@${CONTAINER_CLI} image prune -f
clean: prune