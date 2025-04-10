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
    
    # Make sure we're using the LTS version
    nvm use --lts
    
    # Install global packages for this Node version
    echo "Installing yarn and typescript..."
    npm install -g yarn typescript
   
    echo "Node.js setup complete"
else
    echo "nvm is already installed"
    
    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Make sure we're using the current version
    current_node=$(nvm current)
    
    # Only install global packages if they don't exist
    if ! command -v yarn &> /dev/null || ! command -v tsc &> /dev/null; then
        echo "Installing yarn and typescript for $current_node..."
        npm install -g yarn typescript
    fi
fi