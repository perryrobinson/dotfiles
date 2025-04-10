#!/usr/bin/env bash
# Install SDKMAN for Java version management
echo "Installing SDKMAN..."
if [ ! -d "$HOME/.sdkman" ]; then
    # Make sure zip and unzip are installed
    if ! command -v zip &> /dev/null || ! command -v unzip &> /dev/null; then
        echo "Installing zip and unzip..."
        sudo apt-get update
        sudo apt-get install -y zip unzip
    fi

    curl -s "https://get.sdkman.io" | bash
    
    # Source SDKMAN manually since it's a new installation
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
   
    # Install latest LTS Java
    echo "Installing Java..."
    sdk install java
   
    # Uncomment to install other tools
    # sdk install maven
    # sdk install gradle
   
    echo "Java setup complete"
else
    echo "SDKMAN is already installed"
    # Source SDKMAN to ensure commands work
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
fi