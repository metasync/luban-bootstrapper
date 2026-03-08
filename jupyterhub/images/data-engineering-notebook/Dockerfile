ARG BASE_IMAGE_NAME=quay.io/jupyter/datascience-notebook
ARG BASE_IMAGE_TAG=2026-03-02
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

USER root

# Install system dependencies (zsh, make, git)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    zsh \
    git \
    make \
    curl \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Set Zsh as the default shell for the notebook user
RUN chsh -s /bin/zsh ${NB_USER}
ENV SHELL=/bin/zsh

# Install Oh My Zsh globally
ENV ZSH=/opt/oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# Create global zsh configuration
RUN echo 'export ZSH=/opt/oh-my-zsh' > /etc/zsh/zshrc && \
    echo 'ZSH_THEME="robbyrussell"' >> /etc/zsh/zshrc && \
    echo 'plugins=(git make)' >> /etc/zsh/zshrc && \
    echo 'source $ZSH/oh-my-zsh.sh' >> /etc/zsh/zshrc

# Create init script to suppress zsh new user wizard
RUN mkdir -p /usr/local/bin/before-notebook.d && \
    echo '#!/bin/bash' > /usr/local/bin/before-notebook.d/init-zsh.sh && \
    echo 'if [ ! -f "${HOME}/.zshrc" ]; then' >> /usr/local/bin/before-notebook.d/init-zsh.sh && \
    echo '  touch "${HOME}/.zshrc"' >> /usr/local/bin/before-notebook.d/init-zsh.sh && \
    echo 'fi' >> /usr/local/bin/before-notebook.d/init-zsh.sh && \
    chmod +x /usr/local/bin/before-notebook.d/init-zsh.sh

# Install uv
ARG UV_VERSION
ENV UV_INSTALL_DIR="/usr/local/bin"
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | sh

# Switch back to jovyan user for user-level configurations
USER ${NB_UID}

# Install jupyter-server-proxy
ARG JUPYTER_SERVER_PROXY_VERSION
RUN pip install --no-cache-dir jupyter-server-proxy==${JUPYTER_SERVER_PROXY_VERSION}
