#!/usr/bin/env bash
# Node.js ecosystem configuration

# =============================================================================
# NVM (Node Version Manager)
# Manages Node.js versions - also provides npm and npx
# =============================================================================
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
    source "$NVM_DIR/bash_completion"
fi

# =============================================================================
# Yarn (standalone install at ~/.yarn)
# =============================================================================
[ -d "$HOME/.yarn/bin" ] && export PATH="$HOME/.yarn/bin:$PATH"

# Yarn global packages
[ -d "$HOME/.config/yarn/global/node_modules/.bin" ] && export PATH="$HOME/.config/yarn/global/node_modules/.bin:$PATH"