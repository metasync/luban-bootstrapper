include Makefile.env

# Root orchestration Makefile.
# Installs shared infrastructure first (cert-manager, Envoy Gateway, Gateway)
# and then application components (Argo Workflows, Argo CD, Argo Events, kpack).

.PHONY: help all cert-manager envoy-gateway gateway argo-workflows argo-cd argo-events kpack uninstall uninstall-cert-manager uninstall-envoy-gateway uninstall-gateway uninstall-argo-workflows uninstall-argo-cd uninstall-argo-events uninstall-kpack

help:
	@echo "Usage:"
	@echo "  make all                  Install infra and all components"
	@echo "  make cert-manager         Install cert-manager ($(CERT_MANAGER_VERSION))"
	@echo "  make envoy-gateway        Install Envoy Gateway ($(ENVOY_GATEWAY_VERSION))"
	@echo "  make gateway              Install Gateway API config and local CA issuer"
	@echo "  make argo-workflows       Install Argo Workflows ($(ARGO_WORKFLOWS_VERSION)) into namespace $(ARGO_WORKFLOWS_NAMESPACE)"
	@echo "  make argo-cd              Install Argo CD ($(ARGO_CD_VERSION)) into namespace $(ARGO_CD_NAMESPACE)"
	@echo "  make argo-events          Install Argo Events ($(ARGO_EVENTS_VERSION)) into namespace $(ARGO_EVENTS_NAMESPACE)"
	@echo "  make kpack                Install kpack ($(KPACK_VERSION))"
	@echo "  make uninstall            Uninstall all components and infra"
	@echo "  make uninstall-cert-manager    Uninstall cert-manager"
	@echo "  make uninstall-envoy-gateway   Uninstall Envoy Gateway"
	@echo "  make uninstall-gateway         Uninstall Gateway API config and local CA issuer"
	@echo "  make uninstall-argo-workflows  Uninstall Argo Workflows"
	@echo "  make uninstall-argo-cd         Uninstall Argo CD"
	@echo "  make uninstall-argo-events     Uninstall Argo Events"
	@echo "  make uninstall-kpack           Uninstall kpack"
	@echo ""
	@echo "Environment variables (from Makefile.env):"
	@echo "  KUBECTL                kubectl binary to use"
	@echo "  ARGO_WORKFLOWS_VERSION Argo Workflows version tag"
	@echo "  ARGO_CD_VERSION        Argo CD version tag"
	@echo "  ARGO_EVENTS_VERSION    Argo Events version tag"
	@echo "  KPACK_VERSION          kpack version tag"
	@echo "  ARGO_WORKFLOWS_NAMESPACE Namespace for Argo Workflows"
	@echo "  ARGO_CD_NAMESPACE        Namespace for Argo CD"
	@echo "  ARGO_EVENTS_NAMESPACE    Namespace for Argo Events"
	@echo "  KPACK_NAMESPACE          Namespace for kpack"
	@echo "  ENVOY_GATEWAY_NAMESPACE Namespace for Envoy Gateway"
	@echo "  CERT_MANAGER_NAMESPACE  Namespace for cert-manager"
	@echo "  GATEWAY_NAMESPACE       Namespace for Gateway resources"
	@echo "  ENVOY_GATEWAY_VERSION   Envoy Gateway version"
	@echo "  CERT_MANAGER_VERSION    cert-manager version"
	@echo "  K8S_DOMAIN              Base domain for ingress hosts"
	@echo "  ARGO_WORKFLOWS_HOST     Hostname for Argo Workflows UI"
	@echo "  ARGO_CD_HOST            Hostname for Argo CD UI"

all: cert-manager envoy-gateway gateway argo-workflows argo-cd argo-events kpack

cert-manager:
	@echo "=== Installing cert-manager ==="
	@$(MAKE) -C cert-manager install

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

uninstall: uninstall-argo-workflows uninstall-argo-cd uninstall-argo-events uninstall-kpack uninstall-gateway uninstall-envoy-gateway uninstall-cert-manager

uninstall-cert-manager:
	@echo "=== Uninstalling cert-manager ==="
	@$(MAKE) -C cert-manager uninstall

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
