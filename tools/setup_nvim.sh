#!/usr/bin/env bash
# Neovim setup script (build from source)

set -e
set -o pipefail

# --- Configuration ---
INSTALL_PREFIX="/usr/local" # This is the default install location so this line is redundant but I don't like hidden defaults that are important
NEOVIM_SRC="$HOME/neovim-src"
NEOVIM_CONFIG_DIR="$HOME/.config/nvim"
DOTFILES_NVIM_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config/nvim" && pwd)"
TOOL_CONFIG_DIR="$HOME/.tool_configs"
TOOL_CONFIG_FILE="$TOOL_CONFIG_DIR/nvim.sh"
BACKUP_DIR_BASE="$HOME/.dotfiles_nvim_backup"

# --- Helper Functions ---
info() { echo "INFO: $1"; }
error() {
  echo "ERROR: $1" >&2
  exit 1
}

# --- Check for required tools ---
for cmd in git make; do
  command -v $cmd &>/dev/null || error "$cmd is not installed. Please install build dependencies."
done

# --- Install dependencies ---
info "Installing build dependencies for Neovim..."
sudo apt-get update
sudo apt-get install -y ninja-build gettext cmake curl build-essential fd-find

# --- Get latest stable source ---
if [ -d "$NEOVIM_SRC" ]; then
  info "Updating existing Neovim source"
  cd "$NEOVIM_SRC"
  # Clean up any previous build artifacts
  make distclean
  git fetch origin --tags
  LATEST_STABLE_TAG=$(git tag -l 'v*.*.*' --sort=-v:refname | head -n 1)
  [ -z "$LATEST_STABLE_TAG" ] && error "Could not determine latest stable tag"
  info "Checking out latest stable tag: $LATEST_STABLE_TAG"
  git checkout "$LATEST_STABLE_TAG"
else
  info "Cloning Neovim repository"
  git clone https://github.com/neovim/neovim.git "$NEOVIM_SRC"
  cd "$NEOVIM_SRC"
  LATEST_STABLE_TAG=$(git tag -l 'v*.*.*' --sort=-v:refname | head -n 1)
  [ -z "$LATEST_STABLE_TAG" ] && error "Could not determine latest stable tag"
  info "Checking out latest stable tag: $LATEST_STABLE_TAG"
  git checkout "$LATEST_STABLE_TAG"
fi

# --- Build & Install ---
info "Building and installing Neovim from source (stable tag: $LATEST_STABLE_TAG)..."
cd "$NEOVIM_SRC"
make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
sudo make install

# --- Configuration Setup ---
info "Creating Neovim tool config file..."
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
  info "Backing up existing config to $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  mv "$NEOVIM_CONFIG_DIR" "$BACKUP_DIR/"
fi

# Create symlink for config
info "Setting up Neovim configuration..."
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
  info "Backing up Neovim data directories"
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
  info "Successfully installed: $NVIM_VERSION"
  info "Neovim setup complete! Your config is linked from $DOTFILES_NVIM_CONFIG_DIR"
else
  error "Neovim installation appears to have failed. Check for errors above."
fi

info "Run 'nvim' to start. Ensure your shell sources $TOOL_CONFIG_FILE or $INSTALL_PREFIX/bin is in your PATH."

# --- Clean up build directory ---
read -p "Do you want to remove the build directory ($NEOVIM_SRC)? [y/N]: " -r REMOVE_BUILD
if [[ "$REMOVE_BUILD" =~ ^[Yy]$ ]]; then
  info "Removing build directory..."
  rm -rf "$NEOVIM_SRC"
fi

