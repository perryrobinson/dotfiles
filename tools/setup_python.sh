#!/usr/bin/env bash
# Install uv for Python version and package management
# uv replaces pyenv, pip, pipx, poetry, and virtualenv with a single fast tool

set -e

echo "Installing uv..."

if command -v uv &> /dev/null; then
    echo "uv is already installed, checking for updates..."
    uv self update 2>/dev/null || true
else
    # Install uv via the official installer
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Add to PATH for this session
    export PATH="$HOME/.local/bin:$PATH"
fi

# Verify installation
if ! command -v uv &> /dev/null; then
    echo "Error: uv installation failed"
    exit 1
fi

echo "uv $(uv --version) installed successfully"

# Install a default Python version
echo "Installing Python 3.12..."
uv python install 3.12

# Set Python 3.12 as the default
uv python pin 3.12 --global 2>/dev/null || true

# Install ruff (fast Python linter and formatter)
echo "Installing ruff..."
uv tool install ruff

echo ""
echo "Python setup complete!"
echo ""
echo "Quick reference:"
echo "  uv python list          - List available Python versions"
echo "  uv python install 3.13  - Install a Python version"
echo "  uv init                 - Create a new project"
echo "  uv add requests         - Add a dependency"
echo "  uv run python script.py - Run with project dependencies"
echo "  uv tool install ruff    - Install a CLI tool (like pipx)"
echo ""