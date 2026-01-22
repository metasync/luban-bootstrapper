# Changelog

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
