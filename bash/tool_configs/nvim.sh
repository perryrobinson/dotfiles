#!/usr/bin/env bash
# Neovim configuration (managed by dotfiles setup)

# Add Neovim to the PATH (needed if installed to /usr/local, which is what we are doing when we build neovim from source)
export PATH="/usr/local/bin:$PATH"

# Aliases for Neovim
alias vi="nvim"
alias vim="nvim"