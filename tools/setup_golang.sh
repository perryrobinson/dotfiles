#!/usr/bin/env bash
# Install Go (Golang)

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES_DIR/tools/common.sh"

GO_VERSION="1.22.3"
INSTALL_DIR="/usr/local"
GO_ARCHIVE="go${GO_VERSION}.linux-amd64.tar.gz"
DOWNLOAD_URL="https://golang.org/dl/${GO_ARCHIVE}"

log_header "Go Setup"

log_step 1 "Checking for existing Go installation..."
if [ -d "${INSTALL_DIR}/go" ] && [ -x "${INSTALL_DIR}/go/bin/go" ]; then
    CURRENT_VERSION=$(${INSTALL_DIR}/go/bin/go version | awk '{print $3}' | sed 's/go//')
    if [ "${CURRENT_VERSION}" == "${GO_VERSION}" ]; then
        log_info "Go version ${GO_VERSION} is already installed."
        exit 0
    else
        log_warn "Found existing Go version ${CURRENT_VERSION}. Removing it before installing ${GO_VERSION}..."
        sudo rm -rf "${INSTALL_DIR}/go"
    fi
fi

log_step 2 "Installing Go version ${GO_VERSION}..."

# Check for dependencies
log_detail "Checking for curl..."
if ! command -v curl &> /dev/null; then
    log_warn "curl is not installed. Attempting to install..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y curl
        if ! command -v curl &> /dev/null; then
            die "Failed to install curl. Please install it manually."
        fi
    else
        die "curl is not installed and apt-get is not available."
    fi
fi

log_detail "Downloading Go ${GO_VERSION}..."
curl -LO "${DOWNLOAD_URL}"

if [ ! -f "${GO_ARCHIVE}" ]; then
    die "Failed to download Go archive. Please check the URL or your internet connection."
fi

log_step 3 "Extracting Go archive to ${INSTALL_DIR}..."
sudo tar -C "${INSTALL_DIR}" -xzf "${GO_ARCHIVE}"

if [ ! -d "${INSTALL_DIR}/go" ]; then
    rm -f "${GO_ARCHIVE}"
    die "Failed to extract Go. Check permissions and available space."
fi

log_detail "Cleaning up downloaded archive..."
rm -f "${GO_ARCHIVE}"

log_success "Go ${GO_VERSION} installation complete."
log_info "Please add the following to your shell configuration file (e.g., ~/.bashrc, ~/.zshrc):"
log_separator
echo "export GOROOT=${INSTALL_DIR}/go"
echo "export GOPATH=\$HOME/go"
echo "export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin"
log_separator
log_info "Then, source your configuration file or open a new terminal."
