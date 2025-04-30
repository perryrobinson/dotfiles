#!/usr/bin/env bash
# Neovim removal script (build from source)

set -e
set -o pipefail

# --- Configuration ---
INSTALL_PREFIX="/usr/local"
NEOVIM_SRC="$HOME/neovim-src"
NEOVIM_CONFIG_DIR="$HOME/.config/nvim"
TOOL_CONFIG_DIR="$HOME/.tool_configs"
TOOL_CONFIG_FILE="$TOOL_CONFIG_DIR/nvim.sh"

# --- Helper Functions ---
info() { echo "INFO: $1"; }
warn() { echo "WARN: $1"; }

# --- Uninstall Neovim ---
info "Removing Neovim from system..."

# Use the source directory if it exists to properly uninstall
if [ -d "$NEOVIM_SRC" ]; then
    info "Using existing source directory to uninstall Neovim..."
    cd "$NEOVIM_SRC"
    if sudo make uninstall; then
        info "Neovim uninstalled successfully using 'make uninstall'"
    else
        warn "Failed to uninstall using make. Falling back to manual removal."
        sudo rm -rf "$INSTALL_PREFIX/bin/nvim"
        sudo rm -rf "$INSTALL_PREFIX/share/nvim"
        sudo rm -rf "$INSTALL_PREFIX/lib/nvim"
        sudo rm -rf "$INSTALL_PREFIX/share/man/man1/nvim.1"
    fi
else
    # Manual removal if source directory doesn't exist
    info "No source directory found. Removing Neovim files manually..."
    sudo rm -rf "$INSTALL_PREFIX/bin/nvim"
    sudo rm -rf "$INSTALL_PREFIX/share/nvim"
    sudo rm -rf "$INSTALL_PREFIX/lib/nvim"
    sudo rm -rf "$INSTALL_PREFIX/share/man/man1/nvim.1"
fi

# --- Remove config and data files ---
info "Removing Neovim tool config file..."
rm -rf "$TOOL_CONFIG_FILE"

# Remove config directories
info "Removing Neovim config directory..."
rm -rf "$NEOVIM_CONFIG_DIR"

# Remove data directories
info "Removing Neovim data directories..."
rm -rf "$HOME/.local/share/nvim"
rm -rf "$HOME/.local/state/nvim"
rm -rf "$HOME/.cache/nvim"

# Remove source/build directory if it exists
if [ -d "$NEOVIM_SRC" ]; then
    info "Removing Neovim source directory..."
    rm -rf "$NEOVIM_SRC"
fi

info "Neovim removal complete. You may need to restart your shell for changes to take effect."