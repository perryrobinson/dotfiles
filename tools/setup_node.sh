#!/usr/bin/env bash
# Install Node.js ecosystem: nvm, Node.js, npm, Yarn, TypeScript

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source Logger
if [ -f "$DOTFILES_DIR/bash/bash_logger" ]; then
    source "$DOTFILES_DIR/bash/bash_logger"
else
    echo "Error: bash_logger not found at $DOTFILES_DIR/bash/bash_logger"
    exit 1
fi

# =============================================================================
# Helper Functions
# =============================================================================

load_nvm() {
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

get_latest_nvm_version() {
    local version=""
    if command -v jq &> /dev/null; then
        version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r .tag_name)
    else
        version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    fi

    if [ -z "$version" ]; then
        echo "v0.40.1"  # Fallback version
    else
        echo "$version"
    fi
}

ensure_yarn() {
    if command -v corepack &> /dev/null; then
        log_step "Enabling corepack for Yarn..."
        corepack enable
        # Explicitly prepare yarn to ensure it's installed and ready
        log_detail "Preparing Yarn via corepack..."
        corepack prepare yarn@stable --activate
    else
        log_info "Corepack not available, installing Yarn via npm..."
        npm install -g yarn
    fi
}

ensure_typescript() {
    if ! command -v tsc &> /dev/null; then
        log_step "Installing TypeScript..."
        npm install -g typescript
    else
        log_info "TypeScript already installed: $(tsc --version)"
    fi
}

# =============================================================================
# NVM Installation
# =============================================================================

log_header "Node.js Setup"

if [ ! -d "$HOME/.nvm" ]; then
    NVM_VERSION=$(get_latest_nvm_version)
    log_step "Installing nvm $NVM_VERSION..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
else
    log_info "nvm is already installed"
fi

load_nvm

# =============================================================================
# Node.js Installation
# =============================================================================

if ! command -v node &> /dev/null; then
    log_step "Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts

    log_step "Updating npm to latest..."
    npm install -g npm@latest
else
    log_info "Node.js already installed: $(node --version)"
fi

# =============================================================================
# Yarn Setup (via corepack)
# =============================================================================

if ! command -v yarn &> /dev/null; then
    ensure_yarn
else
    log_info "Yarn already installed: $(yarn --version)"
fi

# =============================================================================
# TypeScript
# =============================================================================

ensure_typescript

# =============================================================================
# Done
# =============================================================================

log_success "Node.js setup complete!"
log_info "Node: $(node --version)"
log_info "npm:  $(npm --version)"

# Check Yarn and TSC versions outside of log_info to avoid subshell hangs/delays holding up the output
YARN_VER="not installed"
if command -v yarn &>/dev/null; then
    # Use timeout to prevent hanging if yarn is still acting up
    YARN_VER=$(timeout 2s yarn --version 2>/dev/null || echo "installed (version check timed out)")
fi

TSC_VER="not installed"
if command -v tsc &>/dev/null; then
    TSC_VER=$(tsc --version)
fi

log_info "Yarn: $YARN_VER"
log_info "tsc:  $TSC_VER"

log_info "Run 'source ~/.bashrc' or start a new terminal to use nvm"
