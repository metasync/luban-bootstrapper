# Changelog

## [Unreleased]


## [v0.6.9] - 2026-03-30

### Changed
- **Argo CD:**
    - Upgraded to App v3.3.6 (Chart v9.4.17).
- **Argo Workflows:**
    - Upgraded to App v4.0.3 (Chart v1.0.6).
    - Upgraded `argo` CLI to v4.0.3.
- **Argo Events:**
    - Upgraded to App v1.9.10 (Chart v2.4.20).
- **Makefiles:**
    - Increased Helm `--timeout` for Argo Workflows and Argo Events installs to improve reliability under slow API/server conditions.

### Fixed
- **Argo Workflows:**
    - Fixed upgrade failures when moving to v4 by removing legacy controller config keys from `argo-workflows-workflow-controller-configmap`.

### Documentation
- Updated README component version references and Argo Workflows example manifest link.


## [v0.6.8] - 2026-03-29

### Added
- **MinIO:**
    - Added MinIO installation using the official `minio/minio` Helm chart.
    - Added Gateway HTTPRoute exposing the MinIO Console on both local and public hostnames.
- **StarRocks (shared-data):**
    - Added StarRocks installation (FE + CN) configured for shared-data mode backed by MinIO.
    - Added Gateway HTTPRoute exposing StarRocks FE HTTP endpoint on both local and public hostnames.
- **Gateway / Routing:**
    - Added consistent `*_PUBLIC_HOST` variables for UI components, derived from `LUBAN_PUBLIC_DOMAIN`.
    - Added `APPS_DOMAIN` / `APPS_PUBLIC_DOMAIN` and `LETSENCRYPT_EMAIL` to centralize domain/email configuration.
- **JupyterHub:**
    - Added `jupyter_scheduler` to the custom `data-engineering-notebook` image.
    - Configured persistent SQLite database storage (`~/.jupyter_scheduler.sqlite`) to ensure schedules and job histories survive pod restarts.

### Changed
- **Gateway / TLS:**
    - Templated Gateway and certificate manifests so listener hostnames and wildcard cert DNS names are derived from `Makefile.env`.
- **HTTPRoutes:**
    - Templated Argo Workflows / Argo CD / Harbor / JupyterHub HTTPRoutes and applied them via `envsubst` for consistency.
- **Documentation:**
    - Updated README to align with new hostname variables, MinIO/StarRocks access, and Gateway templating.

### Fixed
- **Makefiles:**
    - Hardened env file loading for MinIO/StarRocks/Cloudflare secrets to better handle special characters.
    - Improved uninstall robustness for templated HTTPRoutes by ensuring required variables are provided during `envsubst`.

## [v0.6.7] - 2026-03-11

### Added
- **Kubernetes Replicator:**
    - Added Kubernetes Replicator installation (Chart v2.12.3) via `make kubernetes-replicator`.
    - Replaced `reflector` with `kubernetes-replicator` in the `make all` target.
    - Added `uninstall-kubernetes-replicator` target.
- **Argo CD:**
    - Added `make change-password` target to interactively update the admin password.
    - Updated `change-password` to automatically restart the Argo CD server to apply changes immediately.
    - Renamed `get-password` to `get-init-secret` to better reflect its purpose (retrieving the initial Helm-generated secret).
    - Removed `get-password` target entirely as user-set passwords cannot be retrieved (hashing).

### Changed
- **Argo Workflows:**
    - Removed the `SSO_DELEGATE_RBAC_TO_NAMESPACE` environment variable from the server installation configuration, as it is no longer required.
- **Argo CD:**
    - Reverted automatic password patching. The initial admin password is now preserved.

### Removed
- **Reflector:**
    - Completely removed `reflector` from the project in favor of `kubernetes-replicator`.

## [v0.6.6] - 2026-03-10

### Added

- **Reflector:**
    - Added Reflector installation (Chart v10.0.16) via `make reflector`.
    - Included `reflector` in the `make all` target.
    - Added `uninstall-reflector` target.

## [v0.6.5] - 2026-03-08

### Added

- **JupyterHub:**
    - Introduced a custom single-user image (`data-engineering-notebook`) based on `jupyter/datascience-notebook`.
    - Integrated `zsh` with **Oh My Zsh** and `make` autocompletion as the default shell.
    - Pre-installed `uv` (0.10.8) for fast Python package management.
    - Added `jupyter-server-proxy` configuration to support Dagster development (port 3000).
    - Configured dynamic environment variables (`DAGSTER_WEBSERVER_PATH_PREFIX`) for per-user Dagster instances.
    - Enabled access to hidden files (dotfiles) in Jupyter Server.
    - Added comprehensive documentation in `jupyterhub/README.md`.

### Changed

- **JupyterHub:**
    - Updated resource limits to use Burstable QoS (2G Guarantee / 4G Limit) for better memory utilization.
    - Refactored image configuration from `Makefile` to `values.yaml`.
    - Set `imagePullPolicy` to `Always` to ensure the latest image is used on restart.

## [v0.6.4] - 2026-03-04

### Features
-   **Argo Workflows**:
    -   Enabled `SSO_DELEGATE_RBAC_TO_NAMESPACE` to allow namespace-level RBAC delegation when using SSO.

---

## [v0.6.3] - 2026-02-25

### Bug Fixes
-   **Argo Workflows**:
    -   Added `BackendTrafficPolicy` to disable request timeouts for the Argo Workflows UI.
    -   Fixed "Connection closed" errors affecting long-lived SSE connections in the UI.

---

## [v0.6.2] - 2026-02-01

### Features
-   **CLI Support**:
    -   Added `make argo-cli` to install the Argo Workflows CLI (`argo`).
    -   Included `argo` in the `make cli` bundle.
    -   Added version variable `ARGO_CLI_VERSION` to `Makefile.env`.

---

## [v0.6.1] - 2026-02-01

### Documentation
-   **README Updates**:
    -   Added explicit prerequisite section for Cloudflare API Token and domain ownership.
    -   Clarified local vs public access URLs and DNS configuration.

---

## [v0.6.0] - 2026-02-01

### Features
-   **Public Domain Support (Split-Horizon DNS)**:
    -   Implemented support for public access via `*.metasync.cc` domains using Cloudflare.
    -   Integrated `cert-manager` with Let's Encrypt (Prod) and Cloudflare DNS-01 solver for automated public wildcard certificates.
    -   Added `public-ingress.yaml` to manage `ClusterIssuer` and public `Certificate` resources.
    -   Updated Gateway to support dual-stack listeners: `luban-local` (`*.luban.k8s.orb.local`) and `luban-public` (`*.luban.metasync.cc`).
-   **Local Domain Restructuring**:
    -   Renamed local domain structure to `*.luban.k8s.orb.local` for CI tools and `*.apps.k8s.orb.local` for applications.
    -   Migrated all internal apps (Argo CD, Argo Workflows, Harbor) to use the shared wildcard certificate `luban-local-wildcard-tls`, removing the need for per-app certificates.
-   **Infrastructure**:
    -   Updated `cert-manager` installation to use Google DNS (`8.8.8.8`) for recursive lookups to resolve local `SERVFAIL` propagation issues.
    -   Refactored `gateway/resources.yaml` into modular files: `gateway.yaml` (core), `local-ingress.yaml` (PKI), and `public-ingress.yaml` (Let's Encrypt).
    -   Added `secrets/cloudflare.env` support for secure API token management.

---

## [v0.5.0] - 2026-01-28

### Features
-   **Apps Wildcard Support**:
    -   Added `luban-apps` listener on `luban-gateway` to handle `*.apps.k8s.orb.local`.
    -   Added `apps-wildcard` Certificate to manage TLS for the apps wildcard domain automatically.
    -   Updated documentation to mention the new wildcard domain for applications.

---

## [v0.4.0] - 2026-01-28

### Features
-   **Harbor Support**:
    -   Added Harbor installation (App v2.14.0, Chart v1.18.0) via `make harbor`.
    -   Exposed Harbor UI at `https://harbor.k8s.orb.local` using Envoy Gateway.
    -   Configured a dedicated `HTTPRoute` with correct backend service routing (`harbor` service) for full API support.
    -   Added `make -C harbor get-password` to easily retrieve the initial admin password.

---

## [v0.3.0] - 2026-01-26

This release introduces a centralized Wildcard Gateway for scalable service exposure and renames the core gateway resource.

### Gateway & Networking
-   **Renamed Gateway**: `argo-gateway` is now `luban-gateway` to reflect its role as the central entry point for the platform.
-   **Wildcard Support**:
    -   Added a new `luban-ci` listener on `luban-gateway` that handles `*.luban.k8s.orb.local`.
    -   Added a `luban-wildcard` Certificate to manage TLS for the wildcard domain automatically.
-   **Legacy Support**:
    -   Retained dedicated listeners for `argocd.k8s.orb.local` and `argo-workflows.k8s.orb.local` to ensure backward compatibility.
    -   Updated Argo CD and Argo Workflows `HTTPRoute` resources to bind to the new `luban-gateway` while preserving their existing hostnames.

---

## [v0.2.1] - 2026-01-23

### Certificates
-   Set explicit rotation policy for leaf certificates (Argo CD, Argo Workflows):
    -   duration: 2160h (# 90d), renewBefore: 360h (# 15d)
-   Extended local CA validity:
    -   duration: 43800h (# 5y), renewBefore: 720h (# 30d)
-   Added inline readability comments next to hour values.

---

## [v0.2.0] - 2026-01-23

This release switches Envoy Gateway to `GatewayNamespace` mode for better architectural alignment and includes fixes for Argo CD routing.

### Infrastructure

-   **Envoy Gateway**:
    -   Switched deployment mode to `GatewayNamespace`. This ensures Envoy proxies are deployed in the same namespace as the `Gateway` resource (i.e., `gateway` namespace), simplifying traffic management and reducing cross-namespace permissions issues.
-   **Argo CD**:
    -   Verified/Fixed HTTPRoute to correctly reference the centralized `argo-gateway`.

---

## [v0.1.0] - 2026-01-22

This release introduces support for the kpack CLI (`kp`), improved kpack installation logic, and general documentation updates.

### Features

-   **kpack CLI (`kp`) Support**:
    -   Added a new Makefile target `make kp-cli` to install the kpack CLI.
    -   Included `kp` installation in the `make cli` bundle.
    -   The installation logic automatically detects OS/Arch and installs `v0.13.1` by default.
    -   Added logic to check for existing installations to prevent unnecessary downloads.
-   **kpack Installation Improvements**:
    -   Updated `kpack/Makefile` to conditionally handle `GHCR_MIRROR`. It now only attempts to replace `ghcr.io` if the mirror variable is explicitly set, preventing potential issues with empty replacement strings.

### Documentation

-   **README Updates**:
    -   Added `kp` to the list of supported CLIs.
    -   Updated version information in the documentation.
    -   Clarified installation steps for individual components.

---

## [v0.0.3] - 2026-01-20

### Features & Updates

-   **Tool Version Updates**:
    -   Updated various tool versions to their latest stable releases.
-   **Configuration Fixes**:
    -   Fixed configuration issues to ensure smoother deployment.
-   **Documentation**:
    -   Improved documentation for better clarity and usage instructions.

---

## [v0.0.2] - 2026-01-19

### Refactoring & Improvements

-   **Helm Chart Migration**:
    -   Migrated component installations to use Helm charts for better management and configurability.
-   **Makefile Enhancements**:
    -   Improved `make help` output to provide clearer usage information and command descriptions.

---

## [v0.0.1] - 2026-01-19

### Initial Release

-   **Initial Commit**:
    -   Project initialization with basic structure and configuration.
