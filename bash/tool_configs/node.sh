#!/usr/bin/env bash
# Node.js ecosystem configuration

# =============================================================================
# NVM (Node Version Manager) - lazy loaded for fast shell startup
# Manages Node.js versions - also provides npm and npx
# =============================================================================
export NVM_DIR="$HOME/.nvm"

# Add default node to PATH eagerly so `node`, `npm`, `npx` are discoverable
# by scripts, subprocesses, and `which` without sourcing nvm.sh (~200ms).
# nvm itself is still lazy-loaded below for version-switching commands.
if [ -d "$NVM_DIR/versions/node" ]; then
    _nvm_default_dir="$NVM_DIR/versions/node"
    # Resolve the "default" alias, falling back to the highest installed version
    if [ -L "$NVM_DIR/alias/default" ] || [ -f "$NVM_DIR/alias/default" ]; then
        _nvm_default_ver=$(cat "$NVM_DIR/alias/default" 2>/dev/null)
        # nvm aliases can be indirect (e.g. "lts/*" or "node") — resolve to a directory
        case "$_nvm_default_ver" in
            lts/*|node|stable)
                # Pick the highest installed version
                _nvm_default_ver=$(ls -v "$_nvm_default_dir" 2>/dev/null | tail -1)
                ;;
            *)
                # Could be a partial like "22" — find matching directory
                _nvm_match=$(ls -dv "$_nvm_default_dir"/v${_nvm_default_ver}* 2>/dev/null | tail -1)
                if [ -n "$_nvm_match" ]; then
                    _nvm_default_ver=$(basename "$_nvm_match")
                else
                    _nvm_default_ver=$(ls -v "$_nvm_default_dir" 2>/dev/null | tail -1)
                fi
                ;;
        esac
    else
        _nvm_default_ver=$(ls -v "$_nvm_default_dir" 2>/dev/null | tail -1)
    fi

    if [ -d "$_nvm_default_dir/$_nvm_default_ver/bin" ]; then
        export PATH="$_nvm_default_dir/$_nvm_default_ver/bin:$PATH"
    fi
    unset _nvm_default_dir _nvm_default_ver _nvm_match
fi

# Lazy-load nvm: only the `nvm` command itself is wrapped
if [ -s "$NVM_DIR/nvm.sh" ]; then
    nvm() {
        unset -f nvm
        source "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
        nvm "$@"
    }
fi

# pnpm is provided by corepack via the default node installation above.
# No separate PNPM_HOME or PATH entry needed — the corepack shim lives
# in the same bin directory as node/npm/npx.
