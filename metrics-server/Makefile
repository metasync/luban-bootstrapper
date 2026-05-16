include ../Makefile.env

.PHONY: install uninstall check

METRICS_SERVER_REPO_URL ?= https://kubernetes-sigs.github.io/metrics-server/
METRICS_SERVER_CHART_NAME ?= metrics-server/metrics-server

install:
	@$(KUBECTL) create namespace $(METRICS_SERVER_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@helm repo add metrics-server $(METRICS_SERVER_REPO_URL) >/dev/null 2>&1 || true
	@helm repo update metrics-server >/dev/null 2>&1 || true
	@helm upgrade --install $(METRICS_SERVER_RELEASE_NAME) $(METRICS_SERVER_CHART_NAME) \
		--namespace $(METRICS_SERVER_NAMESPACE) \
		--create-namespace \
		--version $(METRICS_SERVER_CHART_VERSION) \
		--values values.yaml \
		--timeout 10m
	@$(KUBECTL) -n $(METRICS_SERVER_NAMESPACE) rollout status deployment/$(METRICS_SERVER_RELEASE_NAME) --timeout=600s

check:
	@$(KUBECTL) -n $(METRICS_SERVER_NAMESPACE) get deployment $(METRICS_SERVER_RELEASE_NAME) >/dev/null
	@$(KUBECTL) get apiservice v1beta1.metrics.k8s.io >/dev/null

uninstall:
	@helm uninstall $(METRICS_SERVER_RELEASE_NAME) -n $(METRICS_SERVER_NAMESPACE) || true
	@$(KUBECTL) delete namespace $(METRICS_SERVER_NAMESPACE) --ignore-not-found=true || true
