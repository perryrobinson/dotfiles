#!/usr/bin/env bash
# Neovim removal script (build from source)

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES_DIR/tools/common.sh"

log_header "Neovim Removal"

# --- Configuration ---
INSTALL_PREFIX="/usr/local"
NEOVIM_SRC="$HOME/neovim-src"
NEOVIM_CONFIG_DIR="$HOME/.config/nvim"
TOOL_CONFIG_DIR="$HOME/.tool_configs"
TOOL_CONFIG_FILE="$TOOL_CONFIG_DIR/nvim.sh"

# --- Uninstall Neovim ---
log_step "Removing Neovim from system..."

# Use the source directory if it exists to properly uninstall
if [ -d "$NEOVIM_SRC" ]; then
    log_info "Using existing source directory to uninstall Neovim..."
    cd "$NEOVIM_SRC"
    if sudo make uninstall >/dev/null 2>&1; then
        log_success "Neovim uninstalled successfully using 'make uninstall'"
    else
        log_warn "Failed to uninstall using make. Falling back to manual removal."
        sudo rm -rf "$INSTALL_PREFIX/bin/nvim"
        sudo rm -rf "$INSTALL_PREFIX/share/nvim"
        sudo rm -rf "$INSTALL_PREFIX/lib/nvim"
        sudo rm -rf "$INSTALL_PREFIX/share/man/man1/nvim.1"
    fi
else
    # Manual removal if source directory doesn't exist
    log_info "No source directory found. Removing Neovim files manually..."
    sudo rm -rf "$INSTALL_PREFIX/bin/nvim"
    sudo rm -rf "$INSTALL_PREFIX/share/nvim"
    sudo rm -rf "$INSTALL_PREFIX/lib/nvim"
    sudo rm -rf "$INSTALL_PREFIX/share/man/man1/nvim.1"
fi

# --- Remove config and data files ---
log_step "Removing configuration and data..."

if [ -f "$TOOL_CONFIG_FILE" ]; then
    log_detail "Removing Neovim tool config file..."
    rm -f "$TOOL_CONFIG_FILE"
fi

# Remove config directories
if [ -d "$NEOVIM_CONFIG_DIR" ] || [ -L "$NEOVIM_CONFIG_DIR" ]; then
    log_detail "Removing Neovim config directory..."
    rm -rf "$NEOVIM_CONFIG_DIR"
fi

# Remove data directories
log_detail "Removing Neovim data directories..."
rm -rf "$HOME/.local/share/nvim"
rm -rf "$HOME/.local/state/nvim"
rm -rf "$HOME/.cache/nvim"

# Remove source/build directory if it exists
if [ -d "$NEOVIM_SRC" ]; then
    log_detail "Removing Neovim source directory..."
    rm -rf "$NEOVIM_SRC"
fi

log_success "Neovim removal complete. You may need to restart your shell for changes to take effect."
