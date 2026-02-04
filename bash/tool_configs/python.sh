#!/usr/bin/env bash
# Python configuration with uv
# uv handles Python versions, virtual environments, and package management

# Add uv and uv-managed tools to PATH
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Enable uv shell completion (optional, improves tab completion)
if command -v uv &> /dev/null; then
    eval "$(uv generate-shell-completion bash 2>/dev/null || true)"
fi