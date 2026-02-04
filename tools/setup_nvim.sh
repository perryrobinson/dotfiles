#!/usr/bin/env bash
# Neovim setup script (build from source)

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source Logger
if [ -f "$DOTFILES_DIR/bash/bash_logger" ]; then
    source "$DOTFILES_DIR/bash/bash_logger"
else
    echo "Error: bash_logger not found at $DOTFILES_DIR/bash/bash_logger"
    exit 1
fi

log_header "Neovim Setup"

# --- Configuration ---
INSTALL_PREFIX="/usr/local"
NEOVIM_SRC="$HOME/neovim-src"
NEOVIM_CONFIG_DIR="$HOME/.config/nvim"
DOTFILES_NVIM_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config/nvim" && pwd)"
TOOL_CONFIG_DIR="$HOME/.tool_configs"
TOOL_CONFIG_FILE="$TOOL_CONFIG_DIR/nvim.sh"
BACKUP_DIR_BASE="$HOME/.dotfiles_nvim_backup"

# --- Check for required tools ---
for cmd in git make; do
    if ! command -v $cmd &>/dev/null; then
        die "$cmd is not installed. Please install build dependencies."
    fi
done

# --- Install dependencies ---
log_step "Installing build dependencies for Neovim..."
if command -v apt-get &>/dev/null; then
    sudo apt-get update >/dev/null
    sudo apt-get install -y ninja-build gettext cmake curl build-essential fd-find >/dev/null
else
    log_warn "apt-get not found. Assuming dependencies are installed or installing manually."
fi

# --- Get latest stable source ---
if [ -d "$NEOVIM_SRC" ]; then
    log_info "Updating existing Neovim source"
    cd "$NEOVIM_SRC"
    # Clean up any previous build artifacts
    make distclean >/dev/null 2>&1 || true
    git fetch origin --tags
    LATEST_STABLE_TAG=$(git tag -l 'v*.*.*' --sort=-v:refname | head -n 1)
    [ -z "$LATEST_STABLE_TAG" ] && die "Could not determine latest stable tag"
    log_info "Checking out latest stable tag: $LATEST_STABLE_TAG"
    git checkout "$LATEST_STABLE_TAG"
else
    log_info "Cloning Neovim repository"
    git clone https://github.com/neovim/neovim.git "$NEOVIM_SRC"
    cd "$NEOVIM_SRC"
    LATEST_STABLE_TAG=$(git tag -l 'v*.*.*' --sort=-v:refname | head -n 1)
    [ -z "$LATEST_STABLE_TAG" ] && die "Could not determine latest stable tag"
    log_info "Checking out latest stable tag: $LATEST_STABLE_TAG"
    git checkout "$LATEST_STABLE_TAG"
fi

# --- Build & Install ---
log_step "Building and installing Neovim from source (stable tag: $LATEST_STABLE_TAG)..."
cd "$NEOVIM_SRC"
# Suppress output unless error
if ! make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" >/dev/null; then
    die "Build failed."
fi
if ! sudo make install >/dev/null; then
    die "Install failed."
fi

# --- Configuration Setup ---
log_step "Creating Neovim tool config file..."
mkdir -p "$TOOL_CONFIG_DIR"
cat >"$TOOL_CONFIG_FILE" <<EOF
#!/usr/bin/env bash
# Neovim configuration (managed by dotfiles setup)

# Add Neovim to the PATH
export PATH="$INSTALL_PREFIX/bin:\$PATH"

# Aliases for Neovim
alias vi="nvim"
alias vim="nvim"
EOF

# --- User Config Backup & Symlink ---
if [ -e "$NEOVIM_CONFIG_DIR" ] || [ -L "$NEOVIM_CONFIG_DIR" ]; then
    BACKUP_DIR="${BACKUP_DIR_BASE}_$(date +%Y%m%d%H%M%S)"
    log_info "Backing up existing config to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    mv "$NEOVIM_CONFIG_DIR" "$BACKUP_DIR/"
fi

# Create symlink for config
log_step "Setting up Neovim configuration..."
mkdir -p "$(dirname "$NEOVIM_CONFIG_DIR")"
ln -sf "$DOTFILES_NVIM_CONFIG_DIR" "$NEOVIM_CONFIG_DIR"

# Backup Neovim data directories if they exist
NVIM_DATA_DIRS=("$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim")
BACKUP_DIR="${BACKUP_DIR_BASE}_$(date +%Y%m%d%H%M%S)"
NEEDS_BACKUP=false

for dir in "${NVIM_DATA_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        NEEDS_BACKUP=true
        break
    fi
done

if $NEEDS_BACKUP; then
    mkdir -p "$BACKUP_DIR/local_share" "$BACKUP_DIR/local_state" "$BACKUP_DIR/cache"
    log_info "Backing up Neovim data directories"
    [ -d "$HOME/.local/share/nvim" ] && mv "$HOME/.local/share/nvim" "$BACKUP_DIR/local_share/"
    [ -d "$HOME/.local/state/nvim" ] && mv "$HOME/.local/state/nvim" "$BACKUP_DIR/local_state/"
    [ -d "$HOME/.cache/nvim" ] && mv "$HOME/.cache/nvim" "$BACKUP_DIR/cache/"
fi

# Create directories for Neovim files
mkdir -p "$HOME/.local/share/nvim/swap"
mkdir -p "$HOME/.local/share/nvim/undo"
mkdir -p "$HOME/.local/share/nvim/backup"

# --- Verification ---
NVIM_CMD="$INSTALL_PREFIX/bin/nvim"
if [ -x "$NVIM_CMD" ]; then
    NVIM_VERSION=$($NVIM_CMD --version | head -n 1)
    log_success "Successfully installed: $NVIM_VERSION"
    log_info "Neovim setup complete! Your config is linked from $DOTFILES_NVIM_CONFIG_DIR"
else
    die "Neovim installation appears to have failed. Check for errors above."
fi

log_info "Run 'nvim' to start. Ensure your shell sources $TOOL_CONFIG_FILE or $INSTALL_PREFIX/bin is in your PATH."

# --- Clean up build directory ---
if confirm "Do you want to remove the build directory ($NEOVIM_SRC)?"; then
    log_step "Removing build directory..."
    rm -rf "$NEOVIM_SRC"
fi
