#!/usr/bin/env bash
# Install SDKMAN and set up the Java environment

set -e # Exit immediately if a command exits with a non-zero status

# Calculate directories
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source Logger
if [ -f "$DOTFILES_DIR/bash/bash_logger" ]; then
    source "$DOTFILES_DIR/bash/bash_logger"
else
    echo "Error: bash_logger not found at $DOTFILES_DIR/bash/bash_logger"
    exit 1
fi

# --- Configuration ---
JAVA_VERSION="21.0.3-tem" # Specify a recent Long-Term Support (LTS) version
MAVEN_VERSION=""          # Let SDKMAN install the latest stable version

log_header "Java Environment Setup"

# --- Installation ---
log_section "SDKMAN Installation"

# Check for dependencies (zip, unzip)
log_step 1 "Checking dependencies..."
if ! command -v zip >/dev/null || ! command -v unzip >/dev/null; then
    if command -v apt-get >/dev/null; then
        log_detail "Installing dependencies: zip, unzip..."
        sudo apt-get update >/dev/null
        sudo apt-get install -y zip unzip >/dev/null
        log_success "Dependencies installed"
    else
        die "zip and unzip are not installed. Please install them manually and re-run this script."
    fi
else
    log_success "Dependencies found (zip, unzip)"
fi

# Install SDKMAN if not already installed
if [ ! -d "$HOME/.sdkman" ]; then
    log_step 2 "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
    # Source SDKMAN to make it available in this script session
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    log_success "SDKMAN installed"
else
    log_success "SDKMAN is already installed."
    # Source SDKMAN to ensure its commands are available
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

log_section "Java & Maven"

# Install specified Java version if not already present
# Using 'sdk home' to check if version exists is more reliable than parsing 'sdk list'
if ! sdk home java "$JAVA_VERSION" >/dev/null 2>&1; then
    log_step 3 "Installing Java version $JAVA_VERSION..."
    sdk install java "$JAVA_VERSION"
    log_success "Java $JAVA_VERSION installed"
else
    log_success "Java version $JAVA_VERSION is already installed."
fi

# Set as default explicitly
sdk default java "$JAVA_VERSION" >/dev/null 2>&1 || true

# Install latest Maven if not already present
# Check if mvn is in path (after sdkman init)
if ! command -v mvn >/dev/null; then
    log_step 4 "Installing latest stable Maven..."
    sdk install maven "$MAVEN_VERSION"
    log_success "Maven installed"
else
    log_success "Maven is already installed."
fi

log_section "Setup Complete"
log_info "Current active versions:"
echo "Java: $(sdk current java)"
echo "Maven: $(sdk current maven)"
