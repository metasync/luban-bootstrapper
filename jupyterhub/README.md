# JupyterHub Deployment

This directory contains the configuration and deployment scripts for JupyterHub on Kubernetes, featuring a custom "Data Engineering Notebook" image tailored for modern development workflows.

## Components

### 1. JupyterHub
The core platform is deployed using the official [Zero to JupyterHub with Kubernetes](https://z2jh.jupyter.org/) Helm chart.

### 2. Custom Single-User Image (`data-engineering-notebook`)
We use a custom Docker image extending the official `jupyter/datascience-notebook` to provide a robust environment for data engineering.

**Key Features:**
*   **Base:** `jupyter/datascience-notebook` (Python, R, Julia, Spark)
*   **Shell:** `zsh` with **Oh My Zsh** and **`make` autocompletion** enabled by default.
*   **Package Management:** `uv` (Fast Python package installer and resolver) pre-installed.
*   **Development Tools:** `git`, `make`, `curl`, `ca-certificates`.
*   **Proxy:** `jupyter-server-proxy` installed to allow accessing local web services (like Dagster) through the JupyterHub interface.

### 3. Gateway Integration
Ingress is managed via **Envoy Gateway** using the `Gateway` API, configured in `gateway.yaml`.

## Configuration

The deployment is configured via `values.yaml`. Key configurations include:

### Resource Limits (Burstable QoS)
To balance resource guarantees with the ability to handle spikes, we use a **Burstable** QoS class:
*   **Memory Guarantee:** 2G (Reserved)
*   **Memory Limit:** 4G (Can burst up to this if node has capacity)
*   **CPU Guarantee:** 0.5 cores
*   **CPU Limit:** 2 cores

### Dagster Integration
The environment is pre-configured for developing Dagster applications:
*   **Proxy Config:** `jupyter-server-proxy` is configured to route traffic from port `3000` (Dagster's default).
*   **Dynamic Environment Variables:** A `KubeSpawner` hook automatically sets `DAGSTER_WEBSERVER_PATH_PREFIX` to `/user/<username>/dagster` for each user, ensuring Dagster's UI works correctly behind the proxy.
*   **Launcher:** A "Dagster" icon appears in the JupyterLab launcher for quick access.

### System Configuration
*   **Hidden Files:** Access to dotfiles (e.g., `.env`, `.git`) is enabled in `jupyter_server_config.py`.
*   **Modern Server:** The container is forced to run `jupyter_server.serverapp.ServerApp` to respect all modern configurations.

## Deployment

### Prerequisites
*   Docker (for building the image)
*   Kubernetes Cluster
*   `kubectl` and `helm`

### 1. Build and Push the Custom Image
If you have modified the Dockerfile or need to update versions, build and push the image first:

```bash
cd images/data-engineering-notebook
make build push
```

*Note: The image is tagged with the date (e.g., `2026-03-02`) defined in `Makefile.env`.*

### 2. Deploy JupyterHub
Deploy or upgrade the Helm release:

```bash
# From the jupyterhub/ directory
make install
```

Or from the project root:
```bash
make workspace
```

Or install only JupyterHub from the project root:

```bash
make jupyterhub
```

## Usage Guide

### Accessing the Shell
Open a Terminal in JupyterLab. You will be dropped into a `zsh` session with:
*   **Oh My Zsh** theme.
*   **Git** status integration.
*   **Make** autocompletion (try typing `make <tab>` in a directory with a Makefile).

### Developing Dagster
1.  Clone your Dagster project.
2.  Install dependencies using `uv` (recommended).
3.  Start the Dagster dev server:
    ```bash
    dagster dev -h 0.0.0.0 -p 3000
    ```
4.  Access the UI via the **Dagster** icon in the launcher, or visit:
    `https://<jupyterhub-host>/user/<username>/dagster/`
