#!/usr/bin/env bash
# Install SDKMAN for Java version management

echo "Installing SDKMAN..."
if [ ! -d "$HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    
    # Install latest LTS Java
    echo "Installing Java..."
    sdk install java
    
    # Uncomment to install other tools
    # sdk install maven
    # sdk install gradle
    
    echo "Java setup complete"
else
    echo "SDKMAN is already installed"
fi