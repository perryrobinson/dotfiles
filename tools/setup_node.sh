#!/usr/bin/env bash

# Install nvm for Node.js version management
echo "Installing nvm..."
if [ ! -d "$HOME/.nvm" ]; then
    # Get latest nvm version
    if command -v jq &> /dev/null; then
        NVM_LATEST=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r .tag_name)
    else
        NVM_LATEST=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    fi
    if [ -z "$NVM_LATEST" ]; then
        echo "Failed to get latest nvm version, using fallback"
        NVM_LATEST="v0.39.7"
    fi
    echo "Installing nvm $NVM_LATEST..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_LATEST/install.sh" | bash
   
    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
   
    # Install latest LTS Node.js
    echo "Installing Node.js LTS..."
    nvm install --lts
    
    # Make sure we're using the LTS version
    nvm use --lts
    
    # Update npm to latest version
    echo "Updating npm to latest version..."
    npm install -g npm@latest
    
    # Enable corepack for modern Yarn (Node 16.10+)
    if command -v corepack &> /dev/null; then
        echo "Enabling corepack for Yarn..."
        corepack enable
    else
        echo "Corepack not available (requires Node 16.10+), installing Yarn via npm..."
        npm install -g yarn
    fi
    
    # Install typescript globally
    echo "Installing typescript..."
    npm install -g typescript
   
    echo "Node.js setup complete"
    echo "Note: You may need to run 'source ~/.bashrc' or start a new terminal to use nvm"
else
    echo "nvm is already installed"
    
    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Check if Node is installed
    if ! command -v node &> /dev/null; then
        echo "No Node.js version found, installing LTS..."
        nvm install --lts
        nvm use --lts
        
        # Update npm to latest version
        echo "Updating npm to latest version..."
        npm install -g npm@latest
    fi
    
    # Enable corepack if not already enabled (Node 16.10+)
    if ! command -v yarn &> /dev/null || [ "$(yarn --version 2>/dev/null | cut -d. -f1)" = "1" ]; then
        if command -v corepack &> /dev/null; then
            echo "Enabling corepack for modern Yarn..."
            corepack enable
        else
            echo "Corepack not available (requires Node 16.10+)"
            if ! command -v yarn &> /dev/null; then
                echo "Installing Yarn via npm..."
                npm install -g yarn
            fi
        fi
    fi
    
    # Install typescript if missing
    if ! command -v tsc &> /dev/null; then
        echo "Installing typescript..."
        npm install -g typescript
    fi
fi

# Install Bun
echo "Installing Bun..."
if [ ! -d "$HOME/.bun" ]; then
    curl -fsSL https://bun.com/install | bash
    echo "Bun installed successfully"
else
    echo "Bun is already installed"
fi

echo "Node.js tools setup complete!"