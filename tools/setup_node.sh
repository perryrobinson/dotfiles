#!/usr/bin/env bash
# Install nvm for Node.js version management

echo "Installing nvm..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
    
    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install latest LTS Node.js
    echo "Installing Node.js LTS..."
    nvm install --lts
    
    echo "Node.js setup complete"
else
    echo "nvm is already installed"
fi