#!/usr/bin/env bash
# install_docker.sh – idempotent Docker + latest Compose installer
# Tested on Ubuntu 22.04 / 24.04 (x86_64 and arm64)

set -euo pipefail

### 0. Helpers -------------------------------------------------------------
log() { printf "\n[\033[1;32mINFO\033[0m] %s\n" "$*"; }
err() { printf "\n[\033[1;31mERROR\033[0m] %s\n" "$*" >&2; exit 1; }

### 1. Detect architecture -------------------------------------------------
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64) ARCH_TAG="x86_64" ;;
    aarch64|arm64) ARCH_TAG="aarch64" ;;
    *) err "Unsupported architecture: $ARCH" ;;
esac

### 2. Install Docker Engine ----------------------------------------------
if ! command -v docker &>/dev/null; then
    log "Installing Docker Engine stable …"
    sudo apt-get update -qq
    sudo apt-get install -y \
        apt-transport-https ca-certificates curl gnupg lsb-release

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) \
      signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt-get update -qq
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl enable --now docker
else
    log "Docker already installed – skipping Engine install."
fi

### 3. Install / Update Docker Compose v2 ----------------------------------
PLUGIN_DIR="/usr/libexec/docker/cli-plugins"
sudo mkdir -p "$PLUGIN_DIR"

# Query GitHub API for the latest Compose release tag
LATEST_TAG=$(curl -fsSL \
    "https://api.github.com/repos/docker/compose/releases/latest" \
    | grep -Po '"tag_name": "\Kv[0-9.]+' )

DEST="$PLUGIN_DIR/docker-compose"
INSTALLED_VERSION=$($DEST version --short 2>/dev/null || echo "none")

if [[ "$INSTALLED_VERSION" != "$LATEST_TAG" ]]; then
    log "Installing Docker Compose $LATEST_TAG …"
    sudo curl -L \
        "https://github.com/docker/compose/releases/download/${LATEST_TAG}/docker-compose-linux-${ARCH_TAG}" \
        -o "$DEST"
    sudo chmod +x "$DEST"
else
    log "Docker Compose already at latest version ($LATEST_TAG)."
fi

### 4. Verify --------------------------------------------------------------
log "Docker version  : $(docker --version)"
log "Compose version : $(docker compose version --short)"

