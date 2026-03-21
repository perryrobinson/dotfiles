#!/usr/bin/env bash
# Node.js ecosystem configuration

# =============================================================================
# NVM (Node Version Manager) - lazy loaded for fast shell startup
# Manages Node.js versions - also provides npm and npx
# =============================================================================
export NVM_DIR="$HOME/.nvm"

# Lazy-load nvm: define placeholder functions that source nvm on first call
if [ -s "$NVM_DIR/nvm.sh" ]; then
    _nvm_lazy_load() {
        unset -f nvm node npm npx
        source "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

        # Enable nvm auto-use after loading (switches node version if .nvmrc present)
        if [ -f .nvmrc ]; then
            nvm use --silent >/dev/null 2>&1
        fi
    }

    nvm()  { _nvm_lazy_load; nvm  "$@"; }
    node() { _nvm_lazy_load; node "$@"; }
    npm()  { _nvm_lazy_load; npm  "$@"; }
    npx()  { _nvm_lazy_load; npx  "$@"; }
fi

# =============================================================================
# pnpm
# =============================================================================
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) [ -d "$PNPM_HOME" ] && export PATH="$PNPM_HOME:$PATH" ;;
esac
