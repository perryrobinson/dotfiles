#!/usr/bin/env bash
# Install Go and golangci-lint with pinned versions
# To upgrade: bump the version variables below and re-run.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES_DIR/tools/common.sh"

# --- Pinned versions (bump these to upgrade) ---
GO_VERSION="1.26.1"
GOLANGCI_LINT_VERSION="2.11.3"

INSTALL_DIR="/usr/local"

log_header "Go Setup"

# --- Detect architecture ---
log_step 1 "Detecting system architecture..."
case "$(uname -m)" in
    x86_64)  ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l)  ARCH="armv6l" ;;
    *)       die "Unsupported architecture: $(uname -m)" ;;
esac

case "$(uname -s)" in
    Linux)  OS="linux" ;;
    Darwin) OS="darwin" ;;
    *)      die "Unsupported OS: $(uname -s)" ;;
esac
log_detail "Detected: ${OS}/${ARCH}"

# --- Install Go ---
log_step 2 "Checking Go installation..."
log_detail "Pinned version: ${GO_VERSION}"

NEED_GO_INSTALL=true
if [ -d "${INSTALL_DIR}/go" ] && [ -x "${INSTALL_DIR}/go/bin/go" ]; then
    CURRENT_VERSION=$(${INSTALL_DIR}/go/bin/go version | awk '{print $3}' | sed 's/go//')
    if [ "${CURRENT_VERSION}" == "${GO_VERSION}" ]; then
        log_info "Go ${GO_VERSION} is already installed."
        NEED_GO_INSTALL=false
    else
        log_warn "Found Go ${CURRENT_VERSION}. Upgrading to ${GO_VERSION}..."
        sudo rm -rf "${INSTALL_DIR}/go"
    fi
fi

if [ "$NEED_GO_INSTALL" = true ]; then
    GO_ARCHIVE="go${GO_VERSION}.${OS}-${ARCH}.tar.gz"
    DOWNLOAD_URL="https://go.dev/dl/${GO_ARCHIVE}"
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    log_step 3 "Installing Go ${GO_VERSION}..."

    log_detail "Downloading ${GO_ARCHIVE}..."
    curl -fsSL "${DOWNLOAD_URL}" -o "${TMPDIR}/${GO_ARCHIVE}"

    log_detail "Extracting to ${INSTALL_DIR}..."
    sudo tar -C "${INSTALL_DIR}" -xzf "${TMPDIR}/${GO_ARCHIVE}"

    if [ ! -d "${INSTALL_DIR}/go" ]; then
        die "Failed to extract Go. Check permissions and available space."
    fi

    log_success "Go ${GO_VERSION} (${OS}/${ARCH}) installed."
fi

# --- Install golangci-lint ---
log_section "golangci-lint Setup"
log_detail "Pinned version: ${GOLANGCI_LINT_VERSION}"

# Ensure GOPATH/bin exists for the install target
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="${INSTALL_DIR}/go/bin:${GOPATH}/bin:${PATH}"

NEED_LINT_INSTALL=true
if command -v golangci-lint &> /dev/null; then
    CURRENT_LINT_VERSION=$(golangci-lint --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
    if [ "${CURRENT_LINT_VERSION}" == "${GOLANGCI_LINT_VERSION}" ]; then
        log_info "golangci-lint ${GOLANGCI_LINT_VERSION} is already installed."
        NEED_LINT_INSTALL=false
    else
        log_warn "Found golangci-lint ${CURRENT_LINT_VERSION}. Upgrading to ${GOLANGCI_LINT_VERSION}..."
    fi
fi

if [ "$NEED_LINT_INSTALL" = true ]; then
    log_step 4 "Installing golangci-lint ${GOLANGCI_LINT_VERSION}..."
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | \
        sh -s -- -b "${GOPATH}/bin" "v${GOLANGCI_LINT_VERSION}"
    log_success "golangci-lint ${GOLANGCI_LINT_VERSION} installed to ${GOPATH}/bin"
fi

log_info "PATH is managed by ~/.tool_configs/golang.sh"
