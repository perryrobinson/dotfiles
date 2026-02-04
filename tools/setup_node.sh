#!/usr/bin/env bash
# Install Node.js ecosystem: nvm, Node.js, npm, Yarn, TypeScript

set -e

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
        echo "Enabling corepack for Yarn..."
        corepack enable
    else
        echo "Corepack not available, installing Yarn via npm..."
        npm install -g yarn
    fi
}

ensure_typescript() {
    if ! command -v tsc &> /dev/null; then
        echo "Installing TypeScript..."
        npm install -g typescript
    else
        echo "TypeScript already installed: $(tsc --version)"
    fi
}

# =============================================================================
# NVM Installation
# =============================================================================

echo "=== Node.js Setup ==="

if [ ! -d "$HOME/.nvm" ]; then
    NVM_VERSION=$(get_latest_nvm_version)
    echo "Installing nvm $NVM_VERSION..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
else
    echo "nvm is already installed"
fi

load_nvm

# =============================================================================
# Node.js Installation
# =============================================================================

if ! command -v node &> /dev/null; then
    echo "Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts

    echo "Updating npm to latest..."
    npm install -g npm@latest
else
    echo "Node.js already installed: $(node --version)"
fi

# =============================================================================
# Yarn Setup (via corepack)
# =============================================================================

if ! command -v yarn &> /dev/null; then
    ensure_yarn
else
    echo "Yarn already installed: $(yarn --version)"
fi

# =============================================================================
# TypeScript
# =============================================================================

ensure_typescript

# =============================================================================
# Done
# =============================================================================

echo ""
echo "Node.js setup complete!"
echo "  Node: $(node --version)"
echo "  npm:  $(npm --version)"
echo "  Yarn: $(yarn --version 2>/dev/null || echo 'not installed')"
echo "  tsc:  $(tsc --version 2>/dev/null || echo 'not installed')"
echo ""
echo "Run 'source ~/.bashrc' or start a new terminal to use nvm"
