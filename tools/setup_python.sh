#!/usr/bin/env bash
# Install pyenv for Python version management

echo "Installing pyenv..."
if [ ! -d "$HOME/.pyenv" ]; then
    # Install dependencies
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
    fi
    
    # Install pyenv
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
    
    # Reload the config to get pyenv working
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    
    # Install latest Python
    echo "Installing latest Python..."
    pyenv install 3.11.0
    pyenv global 3.11.0
    
    echo "Python setup complete"
else
    echo "pyenv is already installed"
fi