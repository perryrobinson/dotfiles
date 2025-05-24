#!/usr/bin/env bash
# Python configuration with pyenv and pipx

if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path 2>/dev/null || true)"
    eval "$(pyenv init - 2>/dev/null || true)"
fi

if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi