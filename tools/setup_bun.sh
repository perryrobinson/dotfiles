#!/usr/bin/env bash
# Install Bun - JavaScript runtime and toolkit

set -e

echo "=== Bun Setup ==="

if [ -d "$HOME/.bun" ]; then
    echo "Bun is already installed"

    # Load bun into current shell
    export PATH="$HOME/.bun/bin:$PATH"

    echo "Current version: $(bun --version)"

    read -p "Do you want to upgrade Bun? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Upgrading Bun..."
        bun upgrade
        echo "Upgraded to: $(bun --version)"
    fi
else
    echo "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash

    # Load bun into current shell
    export PATH="$HOME/.bun/bin:$PATH"

    echo "Bun installed successfully: $(bun --version)"
fi

echo ""
echo "Bun setup complete!"
echo "  Bun: $(bun --version)"
echo ""
echo "Run 'source ~/.bashrc' or start a new terminal to use bun"
