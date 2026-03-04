# Changelog

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
