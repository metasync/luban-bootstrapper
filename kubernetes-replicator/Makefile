include ../Makefile.env

.PHONY: install uninstall

install:
	@if [ "$(FORCE)" != "1" ] && helm status kubernetes-replicator -n $(KUBERNETES_REPLICATOR_NAMESPACE) >/dev/null 2>&1; then \
		echo "kubernetes-replicator already installed (set FORCE=1 to upgrade)"; \
	else \
		echo "Adding Mittwald Helm repository..."; \
		helm repo add mittwald https://helm.mittwald.de; \
		helm repo update mittwald; \
		echo "Installing Kubernetes Replicator (Chart v$(KUBERNETES_REPLICATOR_CHART_VERSION))..."; \
		helm upgrade --install kubernetes-replicator mittwald/kubernetes-replicator \
			--namespace $(KUBERNETES_REPLICATOR_NAMESPACE) \
			--create-namespace \
			--version $(KUBERNETES_REPLICATOR_CHART_VERSION) \
			--values values.yaml \
			--wait; \
	fi

uninstall:
	@echo "Uninstalling Kubernetes Replicator..."
	@helm uninstall kubernetes-replicator -n $(KUBERNETES_REPLICATOR_NAMESPACE) || true
	@echo "Deleting namespace $(KUBERNETES_REPLICATOR_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(KUBERNETES_REPLICATOR_NAMESPACE) --ignore-not-found=true || true
