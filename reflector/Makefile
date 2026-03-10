include ../Makefile.env

.PHONY: install uninstall

install:
	@echo "Adding Reflector Helm repository..."
	@helm repo add emberstack https://emberstack.github.io/helm-charts
	@helm repo update emberstack
	@echo "Installing Reflector (Chart v$(REFLECTOR_CHART_VERSION))..."
	@helm upgrade --install reflector emberstack/reflector \
		--namespace $(REFLECTOR_NAMESPACE) \
		--create-namespace \
		--version $(REFLECTOR_CHART_VERSION) \
		--wait

uninstall:
	@echo "Uninstalling Reflector..."
	@helm uninstall reflector -n $(REFLECTOR_NAMESPACE) || true
	@echo "Deleting namespace $(REFLECTOR_NAMESPACE)..."
	@$(KUBECTL) delete namespace $(REFLECTOR_NAMESPACE) --ignore-not-found=true || true
