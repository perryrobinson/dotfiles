#!/usr/bin/env bash
# Install pyenv for Python version management
echo "Installing pyenv..."
if [ ! -d "$HOME/.pyenv" ]; then
    # Install dependencies if on Debian/Ubuntu
    if command -v apt-get &> /dev/null; then
        echo "Installing pyenv dependencies..."
        sudo apt-get update
        sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
    fi
   
    # Install pyenv
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
   
    # Set up environment for pyenv
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path 2>/dev/null || true)"
    eval "$(pyenv init - 2>/dev/null || true)"
   
    # Install latest Python
    echo "Installing latest Python..."
    pyenv install 3.12.0
    pyenv global 3.12.0
   
    echo "Python setup complete"
else
    echo "pyenv is already installed"
    
    # Set up environment for pyenv
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path 2>/dev/null || true)"
    eval "$(pyenv init - 2>/dev/null || true)"
fi

echo "Setting up pipx..."
if ! command -v pipx &> /dev/null; then
    echo "Installing pipx..."
    pip install --user pipx
    pipx ensurepath
    
    export PATH="$HOME/.local/bin:$PATH"
    
    echo "pipx installed successfully"
else
    echo "pipx is already installed"
fi