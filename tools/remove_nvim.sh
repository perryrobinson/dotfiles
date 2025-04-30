#!/usr/bin/env bash
# Neovim removal script for dotfiles (for build-from-source installations)

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
INSTALL_PREFIX="/usr/local" # Must match the prefix used during install
NEOVIM_SRC="$HOME/neovim-src"
BUILD_DIR="$NEOVIM_SRC/build" # Build directory needed for make uninstall
NEOVIM_CONFIG_DIR="$HOME/.config/nvim"
TOOL_CONFIG_DIR="$HOME/.tool_configs"
TOOL_CONFIG_FILE="$TOOL_CONFIG_DIR/nvim.sh"
# Let user manage backups manually - safer than wildcard deletion
# BACKUP_DIR_BASE="$HOME/.dotfiles_nvim_backup"

# --- Helper Functions ---
info() {
    echo "INFO: $1"
}

warn() {
    echo "WARN: $1"
}

error() {
    echo "ERROR: $1" >&2
    exit 1
}

# --- Main Logic ---

# Method 1: Use 'make uninstall' (Preferred if build dir exists)
if [ -d "$BUILD_DIR" ] && [ -f "$BUILD_DIR/Makefile" ]; then
    info "Attempting uninstall using 'make uninstall' from $BUILD_DIR..."
    cd "$BUILD_DIR"
    # Requires sudo because install went to /usr/local
    if sudo make uninstall; then
        info "'make uninstall' completed successfully."
    else
        warn "'make uninstall' failed. Falling back to manual removal."
        # Fall through to manual removal below
    fi
elif [ -d "$BUILD_DIR" ] && [ -f "$BUILD_DIR/build.ninja" ]; then
     info "Attempting uninstall using 'ninja uninstall' from $BUILD_DIR..."
     cd "$BUILD_DIR"
     # Requires sudo because install went to /usr/local
    if sudo ninja uninstall; then
        info "'ninja uninstall' completed successfully."
    else
        warn "'ninja uninstall' failed. Falling back to manual removal."
        # Fall through to manual removal below
    fi
else
    warn "Build directory $BUILD_DIR or its Makefile/build.ninja not found."
    info "Attempting manual removal of files based on INSTALL_PREFIX=$INSTALL_PREFIX."

    # Method 2: Manual removal (Fallback)
    # Be careful with sudo rm -rf!
    info "Removing Neovim files from $INSTALL_PREFIX..."
    sudo rm -f "$INSTALL_PREFIX/bin/nvim"
    sudo rm -rf "$INSTALL_PREFIX/share/nvim"
    sudo rm -rf "$INSTALL_PREFIX/share/man/man1/nvim.1*" # Man pages
    sudo rm -rf "$INSTALL_PREFIX/share/locale/*/LC_MESSAGES/nvim.mo" # Locale files
    sudo rm -rf "$INSTALL_PREFIX/lib/nvim"
    # CMake might install other files too, 'make uninstall' is more reliable
    warn "Manual removal might leave some files behind. 'make uninstall' is preferred."
fi

info "Removing Neovim tool config file..."
rm -f "$TOOL_CONFIG_FILE"

info "Removing Neovim user configuration symlink/directory..."
if [ -L "$NEOVIM_CONFIG_DIR" ]; then
    info "Removing symlink: $NEOVIM_CONFIG_DIR"
    rm "$NEOVIM_CONFIG_DIR"
elif [ -d "$NEOVIM_CONFIG_DIR" ]; then
    info "Removing directory: $NEOVIM_CONFIG_DIR"
    rm -rf "$NEOVIM_CONFIG_DIR"
else
    warn "Neovim config directory/symlink not found at $NEOVIM_CONFIG_DIR."
fi

info "Removing Neovim user data, state, and cache directories..."
rm -rf "$HOME/.local/share/nvim"
rm -rf "$HOME/.local/state/nvim"
rm -rf "$HOME/.cache/nvim"

# --- Optional Cleanup ---
# warn "Neovim backup directories starting with '$BACKUP_DIR_BASE' were *not* removed."
# warn "Please review and remove them manually from $HOME if desired."

read -p "Do you want to remove the Neovim source directory ($NEOVIM_SRC)? [y/N]: " -r REMOVE_SRC
if [[ "$REMOVE_SRC" =~ ^[Yy]$ ]]; then
    info "Removing source directory $NEOVIM_SRC..."
    rm -rf "$NEOVIM_SRC"
fi

echo
info "Neovim removal complete."
info "Check output for any warnings about manual removal steps."
info "You may need to restart your shell session for PATH/alias changes to fully disappear."