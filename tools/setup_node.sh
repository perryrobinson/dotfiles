#!/usr/bin/env bash
# Install Node.js ecosystem: nvm, Node.js, npm, pnpm, TypeScript

set -eo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES_DIR/tools/common.sh"

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

ensure_pnpm() {
    if ! command -v corepack &> /dev/null; then
        log_error "corepack not found — it ships with Node 16.9+. Check your node installation."
        return 1
    fi
    log_step "Enabling corepack for pnpm..."
    corepack enable
    log_detail "Preparing pnpm@latest via corepack..."
    corepack prepare pnpm@latest --activate
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
    log_step 1 "Installing nvm $NVM_VERSION..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
else
    log_info "nvm is already installed"
fi

load_nvm

# =============================================================================
# Node.js Installation
# =============================================================================

NODE_MAJOR=24

if ! nvm ls "$NODE_MAJOR" &> /dev/null; then
    log_step 2 "Installing Node.js $NODE_MAJOR..."
    nvm install "$NODE_MAJOR"
else
    log_info "Node.js $NODE_MAJOR already installed: $(node --version)"
fi

log_step 3 "Setting Node.js $NODE_MAJOR as default..."
nvm alias default "$NODE_MAJOR"
nvm use "$NODE_MAJOR"

log_detail "Updating npm to latest..."
npm install -g npm@latest

# =============================================================================
# pnpm Setup (via corepack)
# =============================================================================

ensure_pnpm

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

PNPM_VER="not installed"
if command -v pnpm &>/dev/null; then
    PNPM_VER=$(pnpm --version 2>/dev/null || echo "installed (version check failed)")
fi

TSC_VER="not installed"
if command -v tsc &>/dev/null; then
    TSC_VER=$(tsc --version)
fi

log_info "pnpm: $PNPM_VER"
log_info "tsc:  $TSC_VER"

log_info "Run 'source ~/.bashrc' or start a new terminal to use nvm"
set -u
