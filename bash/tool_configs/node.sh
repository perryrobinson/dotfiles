#!/usr/bin/env bash
# Node.js configuration with nvm

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"  # This loads nvm
    source "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"