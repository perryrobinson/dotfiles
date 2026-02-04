#!/usr/bin/env bash
# Install Bun - JavaScript runtime and toolkit

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

log_header "Bun Setup"

if [ -d "$HOME/.bun" ]; then
    log_info "Bun is already installed"

    # Load bun into current shell for version check
    export PATH="$HOME/.bun/bin:$PATH"

    log_info "Current version: $(bun --version)"

    if confirm "Do you want to upgrade Bun?"; then
        log_step "Upgrading Bun..."
        bun upgrade
        log_success "Upgraded to: $(bun --version)"
    fi
else
    log_step "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash

    # Load bun into current shell
    export PATH="$HOME/.bun/bin:$PATH"

    log_success "Bun installed successfully: $(bun --version)"
fi

log_success "Bun setup complete!"
log_info "Bun: $(bun --version)"

log_info "Run 'source ~/.bashrc' or start a new terminal to use bun"
