# Common variables
# Raw OS and Arch detection
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m)
INSTALL_DIR ?= /usr/local/bin

# Shared uninstall helpers to gracefully manage PVC / dangling-PV cleanup.
#
# Usage from per-component Makefiles (order matters):
#   include ../Makefile.env
#   include ../cli/common.mk
#   PURGE_DATA ?= 0        # 0 = keep PVCs and user data (safe default)
#                          # 1 = delete ALL PVCs in the namespace(s), then GC
#                              any Released PVs whose claimRef pointed at
#                              those namespaces. No recovery.
#
# In the uninstall target, perform two inlined steps per component (they are
# specific to each chart/HTTPRoute template, so they are NOT helpers here):
#   1. `helm uninstall <release> -n <namespace> || true`
#   2. delete Gateway HTTPRoute via envsubst:
#        envsubst '$FOO $BAR' < <template.yaml> | kubectl delete -f - --ignore-not-found || true
#   3. Finally call:  $(call purge-namespace, <namespace>)
#
# The only shared helpers defined below are:
#   kubectl-delete-if            → run kubectl delete ignore-not-found
#   purge-ns-pvcs-if-requested   → delete ns PVCs when PURGE_DATA=1 (wait loop)
#   purge-released-pvs-for-ns    → delete cluster-wide Released/Failed PVs by claimRef ns
#   purge-namespace              → combine (PVC delete first, then NS delete, then Released PVs)
#
# Each helper is idempotent (--ignore-not-found / || true) and safe to
# re-run on partially uninstalled clusters.
#
# Notes on PVC reclaim policy:
#   OrbStack / local-path default StorageClass ships with
#   reclaimPolicy = Delete, which means kubelet deletes the PV immediately
#   after the bound PVC is removed.
#
#   Some CRD operators (ECK, StarRocks etc) or manual PV edits can leave
#   reclaimPolicy = Retain, which orphans the PV in phase=Released after
#   PVC delete. We garbage-collect those explicitly here.

define kubectl-delete-if
	@$(KUBECTL) delete $(1) --ignore-not-found=true || true
endef

# 1. Capture PVC names in $1=namespace, $2=marker env var, delete them when PURGE_DATA=1.
#    Waits up to PURGE_WAIT seconds (default 180s) for kubelet finalizers.
PURGE_WAIT ?= 180

define purge-ns-pvcs-if-requested
	@NS=$(1); \
	if [ "$(PURGE_DATA)" = "1" ]; then \
		PVCS=$$( $(KUBECTL) -n $$NS get pvc --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null | tr '\n' ' ' ); \
		if [ -n "$$PVCS" ]; then \
			echo "  [purge] PURGE_DATA=1  -> deleting PVCs in ns=$$NS: $$PVCS"; \
			$(KUBECTL) -n $$NS delete pvc $$PVCS --ignore-not-found=true || true; \
			echo "  [purge] waiting up to $(PURGE_WAIT)s for PVC deletions and PV finalizers..."; \
			DEADLINE=$$(($$(date +%s) + $(PURGE_WAIT))); \
			REMAINING=""; \
			while [ $$(date +%s) -lt $$DEADLINE ]; do \
				REMAINING=$$( $(KUBECTL) -n $$NS get pvc --no-headers 2>/dev/null | wc -l | tr -d ' ' ); \
				[ "$$REMAINING" = "0" ] && break; \
				sleep 5; \
			done; \
			if [ "$$REMAINING" != "0" ]; then \
				echo "  [purge] WARNING: $$REMAINING PVCs still exist in ns=$$NS after PURGE_WAIT=$(PURGE_WAIT)s. Proceeding with namespace delete — the namespace may hang in Terminating until PVC finalizers clear."; \
			fi; \
		else \
			echo "  [purge] PURGE_DATA=1  -> no PVCs found in ns=$$NS (nothing to delete)."; \
		fi; \
	else \
		echo "  [keep]  PURGE_DATA=0  -> PVCs in ns=$$NS preserved (set PURGE_DATA=1 to wipe user data)."; \
	fi
endef

# 2. Garbage-collect any Released/Failed PVs whose .spec.claimRef.namespace is in $1.
#    Safe to run AFTER namespace+PVC deletion. No-op if reclaimPolicy already = Delete.
define purge-released-pvs-for-ns
	@NS=$(1); \
	echo "  [purge] Released-PV garbage-collect pass for claimRef.namespace=$$NS"; \
	PVS=$$( $(KUBECTL) get pv --no-headers -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\t"}{.spec.claimRef.namespace}{"\n"}{end}' 2>/dev/null \
	       | awk -F'\t' -v ns="$$NS" '$$2 ~ /Released|Failed/ && $$3 == ns {print $$1}' ); \
	if [ -n "$$PVS" ]; then \
		echo "          -> deleting orphan PVs: $$PVS"; \
		$(KUBECTL) delete pv $$PVS --ignore-not-found=true || true; \
	else \
		echo "          -> no orphan Released/Failed PVs found for $$NS."; \
	fi
endef

# 3. Combined namespace purge order: PVCs FIRST → then any leftover helm release →
#    then namespace object → then Released PVs. (This is the safe order to avoid
#    stuck namespace finalizers that reference deleted PVC provisioners).
define purge-namespace
	$(call purge-ns-pvcs-if-requested,$(1))
	@echo "  [purge] deleting namespace $(1) ..."; \
	$(KUBECTL) delete namespace $(1) --ignore-not-found=true || true
	$(call purge-released-pvs-for-ns,$(1))
endef
