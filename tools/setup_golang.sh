#!/usr/bin/env bash
# Install Go (Golang)

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES_DIR/tools/common.sh"

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

# --- Fetch latest stable version ---
log_step 2 "Checking for latest Go version..."
GO_VERSION=$(curl -sL 'https://go.dev/VERSION?m=text' | head -1 | sed 's/^go//')
if [ -z "$GO_VERSION" ]; then
    die "Could not determine latest Go version. Check your internet connection."
fi
log_detail "Latest stable: ${GO_VERSION}"

# --- Check existing installation ---
if [ -d "${INSTALL_DIR}/go" ] && [ -x "${INSTALL_DIR}/go/bin/go" ]; then
    CURRENT_VERSION=$(${INSTALL_DIR}/go/bin/go version | awk '{print $3}' | sed 's/go//')
    if [ "${CURRENT_VERSION}" == "${GO_VERSION}" ]; then
        log_info "Go ${GO_VERSION} is already installed."
        exit 0
    else
        log_warn "Found Go ${CURRENT_VERSION}. Upgrading to ${GO_VERSION}..."
        sudo rm -rf "${INSTALL_DIR}/go"
    fi
fi

# --- Download to temp directory ---
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
log_info "PATH is managed by ~/.tool_configs/golang.sh"
