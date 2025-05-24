#!/usr/bin/env bash

GO_VERSION="1.22.3"
INSTALL_DIR="/usr/local"
GO_ARCHIVE="go${GO_VERSION}.linux-amd64.tar.gz"
DOWNLOAD_URL="https://golang.org/dl/${GO_ARCHIVE}"

echo "Checking for existing Go installation..."
if [ -d "${INSTALL_DIR}/go" ] && [ -x "${INSTALL_DIR}/go/bin/go" ]; then
    CURRENT_VERSION=$(${INSTALL_DIR}/go/bin/go version | awk '{print $3}' | sed 's/go//')
    if [ "${CURRENT_VERSION}" == "${GO_VERSION}" ]; then
        echo "Go version ${GO_VERSION} is already installed."
        exit 0
    else
        echo "Found existing Go version ${CURRENT_VERSION}. Removing it before installing ${GO_VERSION}..."
        sudo rm -rf "${INSTALL_DIR}/go"
    fi
fi

echo "Installing Go version ${GO_VERSION}..."

# Check for dependencies
echo "Checking for curl..."
if ! command -v curl &> /dev/null; then
    echo "curl is not installed. Please install curl and try again."
    if command -v apt-get &> /dev/null; then
        echo "Attempting to install curl using apt-get..."
        sudo apt-get update
        sudo apt-get install -y curl
        if ! command -v curl &> /dev/null; then
            echo "Failed to install curl. Please install it manually."
            exit 1
        fi
    else
        exit 1
    fi
fi

echo "Downloading Go ${GO_VERSION}..."
curl -LO "${DOWNLOAD_URL}"

if [ ! -f "${GO_ARCHIVE}" ]; then
    echo "Failed to download Go archive. Please check the URL or your internet connection."
    exit 1
fi

echo "Extracting Go archive to ${INSTALL_DIR}..."
sudo tar -C "${INSTALL_DIR}" -xzf "${GO_ARCHIVE}"

if [ ! -d "${INSTALL_DIR}/go" ]; then
    echo "Failed to extract Go. Check permissions and available space."
    rm -f "${GO_ARCHIVE}"
    exit 1
fi

echo "Cleaning up downloaded archive..."
rm -f "${GO_ARCHIVE}"

echo "Go ${GO_VERSION} installation complete."
echo "Please add the following to your shell configuration file (e.g., ~/.bashrc, ~/.zshrc):"
echo ""
echo "export GOROOT=${INSTALL_DIR}/go"
echo "export GOPATH=\$HOME/go"
echo "export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin"
echo ""
echo "Then, source your configuration file or open a new terminal."
