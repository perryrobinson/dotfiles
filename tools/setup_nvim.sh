#!/usr/bin/env bash
# Neovim setup script for dotfiles (build from source - corrected)

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Causes pipelines to fail on the first command that fails

# --- Configuration ---
INSTALL_PREFIX="/usr/local" # Standard location, requires sudo for install
NEOVIM_SRC="$HOME/neovim-src"
BUILD_DIR="$NEOVIM_SRC/build" # Build happens here
NEOVIM_CONFIG_DIR="$HOME/.config/nvim"
DOTFILES_NVIM_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config/nvim" && pwd)" # Assumes nvim config is in dotfiles/config/nvim
TOOL_CONFIG_DIR="$HOME/.tool_configs"
TOOL_CONFIG_FILE="$TOOL_CONFIG_DIR/nvim.sh"
BACKUP_DIR_BASE="$HOME/.dotfiles_nvim_backup" # More specific backup name

# --- Helper Functions ---
info() {
    echo "INFO: $1"
}

error() {
    echo "ERROR: $1" >&2
    exit 1
}

# --- Pre-checks ---
if ! command -v git &> /dev/null; then
    error "git is not installed. Please install git."
fi
if ! command -v cmake &> /dev/null; then
    error "cmake is not installed. Please install build dependencies."
fi
if ! command -v make &> /dev/null; then # Neovim build uses Make or Ninja
    error "make is not installed. Please install build dependencies."
fi
if ! command -v ninja &> /dev/null; then # Often preferred/faster
    info "ninja-build not found, Make will be used. Install 'ninja-build' for potentially faster builds."
fi


# --- Dependencies ---
info "Installing/updating build dependencies for Neovim..."
sudo apt-get update
# Combined dependencies list from Neovim docs
sudo apt-get install -y ninja-build gettext cmake unzip curl \
                        build-essential \
                        libtool libtool-bin autoconf automake pkg-config \
                        g++

# --- Source Code ---
if [ -d "$NEOVIM_SRC" ]; then
    info "Updating existing Neovim source at $NEOVIM_SRC"
    cd "$NEOVIM_SRC"
    # Fetch updates from remote, discard local changes, checkout latest stable tag
    git fetch origin --tags
    # Get the latest tag name (heuristic: highest version number)
    LATEST_STABLE_TAG=$(git tag -l 'v*.*.*' --sort=-v:refname | head -n 1)
    if [ -z "$LATEST_STABLE_TAG" ]; then
        error "Could not determine latest stable tag (e.g., v0.10.0)."
    fi
    info "Checking out latest stable tag: $LATEST_STABLE_TAG"
    git checkout "$LATEST_STABLE_TAG"
    # Optional: Clean up old branches if needed
    # git gc --prune=now
    # git remote prune origin
else
    info "Cloning Neovim repository to $NEOVIM_SRC..."
    # Clone only the stable branch initially if desired, or clone all and checkout later
    # git clone --depth 1 --branch stable https://github.com/neovim/neovim.git "$NEOVIM_SRC"
    git clone https://github.com/neovim/neovim.git "$NEOVIM_SRC"
    cd "$NEOVIM_SRC"
    LATEST_STABLE_TAG=$(git tag -l 'v*.*.*' --sort=-v:refname | head -n 1)
    if [ -z "$LATEST_STABLE_TAG" ]; then
        error "Could not determine latest stable tag (e.g., v0.10.0)."
    fi
    info "Checking out latest stable tag: $LATEST_STABLE_TAG"
    git checkout "$LATEST_STABLE_TAG"
fi

# --- Build ---
info "Building Neovim from source (stable tag: $LATEST_STABLE_TAG)..."
info "Source directory: $NEOVIM_SRC"
info "Build directory: $BUILD_DIR"

# Defensive check: Ensure variables are not empty
if [ -z "$NEOVIM_SRC" ] || [ -z "$BUILD_DIR" ]; then
    error "NEOVIM_SRC or BUILD_DIR variable is empty. Check script configuration."
fi
if [ "$NEOVIM_SRC" == "$BUILD_DIR" ]; then
    error "Build directory cannot be the same as the source directory!"
fi

info "Cleaning up previous build directory: $BUILD_DIR"
rm -rf "$BUILD_DIR"
info "Creating build directory: $BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Check if mkdir succeeded and it's a directory
if [ ! -d "$BUILD_DIR" ]; then
    error "Failed to create build directory: $BUILD_DIR. Check permissions in $NEOVIM_SRC."
fi
info "Successfully created or found directory: $BUILD_DIR"

# --- Debugging CD ---
info "Current directory BEFORE cd: $(pwd)" # DEBUG
info "Attempting to change directory to: $BUILD_DIR" # DEBUG
cd "$BUILD_DIR"
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    error "Failed to 'cd' into build directory '$BUILD_DIR'. Exit code: $EXIT_CODE"
fi

info "Current directory AFTER cd: $(pwd)" # DEBUG

# Verify we are actually in the build directory now
CURRENT_DIR=$(pwd)
if [ "$CURRENT_DIR" != "$BUILD_DIR" ]; then
    error "Failed to change directory! Expected '$BUILD_DIR', but still in '$CURRENT_DIR'."
fi
info "Successfully changed directory."
# --- End Debugging CD ---

info "Running CMake configure step from $(pwd)..."

# Define arguments clearly
CMAKE_ARGS=("-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX" "-DCMAKE_BUILD_TYPE=Release" "$NEOVIM_SRC")

info "Executing: cmake ${CMAKE_ARGS[@]}" # Print the intended command

# Execute CMake directly with arguments
cmake "${CMAKE_ARGS[@]}"
if [ $? -ne 0 ]; then
    error "CMake configuration failed. Check output above and CMake logs (e.g., $BUILD_DIR/CMakeFiles/CMakeOutput.log)."
fi

info "Compiling Neovim (using $(command -v ninja || command -v make))... This may take a while."
# Use ninja if available, otherwise make
cmake --build . --config Release
if [ $? -ne 0 ]; then
    error "CMake build (compilation) failed."
fi

# --- Install ---
info "Installing Neovim to $INSTALL_PREFIX..."
sudo cmake --build . --config Release --target install
if [ $? -ne 0 ]; then
   error "CMake install failed. Check permissions for $INSTALL_PREFIX."
fi

# --- Configuration Setup (Same as .deb version) ---
info "Creating Neovim tool config file..."
mkdir -p "$TOOL_CONFIG_DIR"
cat > "$TOOL_CONFIG_FILE" << EOF
#!/usr/bin/env bash
# Neovim configuration (managed by dotfiles setup)

# Add Neovim to the PATH (needed if installed to /usr/local)
export PATH="$INSTALL_PREFIX/bin:\$PATH"

# Aliases for Neovim
alias vi="nvim"
alias vim="nvim"
EOF

# --- User Config Backup & Symlink (Same as .deb version) ---
if [ -e "$NEOVIM_CONFIG_DIR" ] || [ -L "$NEOVIM_CONFIG_DIR" ]; then
    BACKUP_DIR="${BACKUP_DIR_BASE}_$(date +%Y%m%d%H%M%S)"
    info "Backing up existing Neovim config $NEOVIM_CONFIG_DIR to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    mv "$NEOVIM_CONFIG_DIR" "$BACKUP_DIR/"
fi

info "Creating symlink for Neovim configuration..."
mkdir -p "$(dirname "$NEOVIM_CONFIG_DIR")" # Ensure ~/.config exists
ln -sf "$DOTFILES_NVIM_CONFIG_DIR" "$NEOVIM_CONFIG_DIR"

# Backup other Neovim directories (Same as .deb version)
NVIM_DATA_DIRS=("$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim")
BACKUP_DIR="${BACKUP_DIR_BASE}_$(date +%Y%m%d%H%M%S)" # Use a fresh timestamp dir if needed
NEEDS_BACKUP_DIR=false
for dir in "${NVIM_DATA_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        NEEDS_BACKUP_DIR=true
        break
    fi
done

if $NEEDS_BACKUP_DIR; then
    mkdir -p "$BACKUP_DIR/local_share" "$BACKUP_DIR/local_state" "$BACKUP_DIR/cache"
    info "Backing up Neovim data/state/cache directories to $BACKUP_DIR"
    [ -d "$HOME/.local/share/nvim" ] && mv "$HOME/.local/share/nvim" "$BACKUP_DIR/local_share/"
    [ -d "$HOME/.local/state/nvim" ] && mv "$HOME/.local/state/nvim" "$BACKUP_DIR/local_state/"
    [ -d "$HOME/.cache/nvim" ] && mv "$HOME/.cache/nvim" "$BACKUP_DIR/cache/"
fi

# Create directory for Neovim swap/undo/backup files (Same as .deb version)
mkdir -p "$HOME/.local/share/nvim/swap"
mkdir -p "$HOME/.local/share/nvim/undo"
mkdir -p "$HOME/.local/share/nvim/backup"

# --- Verification ---
if ! command -v nvim &> /dev/null; then
    # Double check if it's in the *expected* install path
    if [ -x "$INSTALL_PREFIX/bin/nvim" ]; then
        warn "Neovim installed to $INSTALL_PREFIX/bin/nvim, but not found in PATH immediately."
        warn "Try starting a new shell or running 'source $TOOL_CONFIG_FILE'."
        NVIM_CMD="$INSTALL_PREFIX/bin/nvim"
    else
        error "Neovim command 'nvim' not found after installation. Check build logs in $BUILD_DIR."
    fi
else
    NVIM_CMD="nvim"
fi

NVIM_VERSION=$($NVIM_CMD --version | head -n 1)
info "Successfully installed: $NVIM_VERSION"
echo
info "Neovim setup complete (built from source)!"
info "Your config is linked from $DOTFILES_NVIM_CONFIG_DIR"
info "Run 'nvim' to start. LazyVim/Plugin manager should initialize."
info "Note: Ensure your shell startup files (e.g., .bashrc) source configs from $TOOL_CONFIG_DIR or that $INSTALL_PREFIX/bin is in your PATH."