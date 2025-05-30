#!/usr/bin/env bash
# Install SDKMAN and set up the Java environment

set -e # Exit immediately if a command exits with a non-zero status

# --- Configuration ---
JAVA_VERSION="21.0.3-tem" # Specify a recent Long-Term Support (LTS) version
MAVEN_VERSION=""          # Let SDKMAN install the latest stable version

# --- Helper Functions ---
info() { echo "INFO: $1"; }
warn() { echo "WARN: $1"; }

# --- Installation ---
info "Setting up Java environment with SDKMAN..."

# Check for dependencies (zip, unzip)
if ! command -v zip >/dev/null || ! command -v unzip >/dev/null; then
    if command -v apt-get >/dev/null; then
        info "Installing dependencies: zip, unzip..."
        sudo apt-get update
        sudo apt-get install -y zip unzip
    else
        warn "zip and unzip are not installed. Please install them manually and re-run this script."
        exit 1
    fi
fi

# Install SDKMAN if not already installed
if [ ! -d "$HOME/.sdkman" ]; then
    info "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
    # Source SDKMAN to make it available in this script session
    source "$HOME/.sdkman/bin/sdkman-init.sh"
else
    info "SDKMAN is already installed."
    # Source SDKMAN to ensure its commands are available
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Install specified Java version if not already present
if ! sdk list java | grep -q " installed" | grep -q "$JAVA_VERSION"; then
    info "Installing Java version $JAVA_VERSION..."
    sdk install java "$JAVA_VERSION"
else
    info "Java version $JAVA_VERSION is already installed."
fi

# Install latest Maven if not already present
if ! sdk list maven | grep -q " installed"; then
    info "Installing latest stable Maven..."
    sdk install maven "$MAVEN_VERSION" # Passing empty string installs the latest
else
    info "Maven is already installed."
fi

info "Java and Maven setup complete."
info "Current active versions:"
sdk current java
sdk current maven