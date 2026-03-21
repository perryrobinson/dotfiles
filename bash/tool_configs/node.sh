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
# pnpm
# =============================================================================
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) [ -d "$PNPM_HOME" ] && export PATH="$PNPM_HOME:$PATH" ;;
esac