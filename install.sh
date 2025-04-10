#!/usr/bin/env bash
# Dotfiles installation script
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d%H%M%S)"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup existing files
for file in .bashrc .bash_aliases .bash_functions .bash_paths .bash_secrets; do
    if [ -f "$HOME/$file" ] || [ -L "$HOME/$file" ]; then
        echo "Backing up $HOME/$file"
        mv "$HOME/$file" "$BACKUP_DIR/"
    fi
done

# Link configuration files
ln -sf "$DOTFILES_DIR/bash/bashrc" "$HOME/.bashrc"
ln -sf "$DOTFILES_DIR/bash/bash_aliases" "$HOME/.bash_aliases"
ln -sf "$DOTFILES_DIR/bash/bash_functions" "$HOME/.bash_functions"
ln -sf "$DOTFILES_DIR/bash/bash_paths" "$HOME/.bash_paths"

# Create secrets file from template if it doesn't exist
if [ ! -f "$HOME/.bash_secrets" ]; then
    echo "Creating ~/.bash_secrets from template"
    cp "$DOTFILES_DIR/bash/bash_secrets.template" "$HOME/.bash_secrets"
    echo "Please edit ~/.bash_secrets to add your actual credentials"
fi

# Create tool configs directory and link files
mkdir -p "$HOME/.tool_configs"
for file in "$DOTFILES_DIR/bash/tool_configs/"*.sh; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        ln -sf "$file" "$HOME/.tool_configs/$filename"
    fi
done

# Source the bashrc to get the environment ready
source "$HOME/.bashrc"

# Install packages if on Debian/Ubuntu
if command -v apt-get &> /dev/null; then
    read -p "Do you want to install essential packages? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing essential packages..."
        
        # Set timezone to America/Chicago (CST)
        echo "Setting timezone to America/Chicago..."
        sudo ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
        echo "America/Chicago" | sudo tee /etc/timezone > /dev/null
        
        sudo apt-get update
        
        # Read packages from essentials.txt file
        if [ -f "$DOTFILES_DIR/packages/essentials.txt" ]; then
            xargs sudo apt-get install -y < "$DOTFILES_DIR/packages/essentials.txt"
        else
            # Fallback if file doesn't exist
            sudo apt-get install -y build-essential curl wget git htop jq zip unzip net-tools tree dos2unix
        fi
        
        # Install Docker if not already installed
        if ! command -v docker &> /dev/null; then
            read -p "Do you want to install Docker? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Installing Docker..."
                curl -fsSL https://get.docker.com | sh
                sudo usermod -aG docker $USER
                echo "You may need to log out and back in for Docker permissions to take effect"
            fi
        fi
        
        # Install Docker Compose if not already installed
        if ! command -v docker-compose &> /dev/null; then
            read -p "Do you want to install Docker Compose? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Installing Docker Compose..."
                sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
            fi
        fi
    fi
fi

# Make setup scripts executable
chmod +x "$DOTFILES_DIR/tools/"*.sh

# Function to install development tools
install_dev_tools() {
    # Source the bashrc to ensure environment is up to date
    source "$HOME/.bashrc"
    
    # Install Java with SDKMAN
    read -p "Do you want to install Java (using SDKMAN)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing Java..."
        bash "$DOTFILES_DIR/tools/setup_java.sh"
        # Need to source again after installing SDKMAN
        source "$HOME/.bashrc"
    fi
    
    # Install Python with pyenv
    read -p "Do you want to install Python (using pyenv)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing Python..."
        bash "$DOTFILES_DIR/tools/setup_python.sh"
        # Need to source again after installing pyenv
        source "$HOME/.bashrc"
    fi
    
    # Install Node.js with nvm
    read -p "Do you want to install Node.js (using nvm)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing Node.js..."
        bash "$DOTFILES_DIR/tools/setup_node.sh"
        # Need to source again after installing nvm
        source "$HOME/.bashrc"
    fi
}

# Ask if the user wants to install development tools
read -p "Do you want to set up development tools now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    install_dev_tools
else
    echo "You can set up development tools later by running:"
    echo "  ./tools/setup_java.sh    - Install SDKMAN for Java"
    echo "  ./tools/setup_python.sh  - Install pyenv for Python"
    echo "  ./tools/setup_node.sh    - Install nvm for Node.js"
fi

echo "Dotfiles installation complete!"
echo "Please log out and log back in to ensure all changes are applied."