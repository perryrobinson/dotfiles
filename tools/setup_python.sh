#!/usr/bin/env bash
# Install uv for Python version and package management
# uv replaces pyenv, pip, pipx, poetry, and virtualenv with a single fast tool

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES_DIR/tools/common.sh"

log_header "Python Setup (uv)"

log_section "Installing uv"

if command -v uv &> /dev/null; then
    log_info "uv is already installed, checking for updates..."
    uv self update 2>/dev/null || true
    log_success "uv updated"
else
    log_step 1 "Installing uv..."
    # Install uv via the official installer
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Add to PATH for this session
    export PATH="$HOME/.local/bin:$PATH"
    log_success "uv installed"
    
    # Note for the user about PATH
    log_detail "Note: ~/.local/bin is automatically added to PATH by ~/.bash_paths"
fi

# Verify installation
if ! command -v uv &> /dev/null; then
    die "uv installation failed"
fi

log_success "uv $(uv --version) ready"

log_section "Python Environment"

# Install a default Python version
log_step 2 "Installing Python 3.12..."
uv python install 3.12 --default
log_success "Python 3.12 installed (python3 available on PATH)"

# Set Python 3.12 as the default
log_step 3 "Pinning Python 3.12 as global default..."
uv python pin 3.12 --global 2>/dev/null || true
log_success "Global python version set"

# Install ruff (fast Python linter and formatter)
log_step 4 "Installing ruff (linter/formatter)..."
uv tool install ruff
log_success "ruff installed"

log_section "Setup Complete"
log_info "Quick reference:"
log_kv "uv python list" "List available Python versions"
log_kv "uv python install" "Install a Python version"
log_kv "uv init" "Create a new project"
log_kv "uv add" "Add a dependency"
log_kv "uv run" "Run with project dependencies"
log_kv "uv tool install" "Install a CLI tool (like pipx)"
