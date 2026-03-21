#!/usr/bin/env bash
# Python configuration with uv
# uv handles Python versions, virtual environments, and package management

# Note: $HOME/.local/bin is added in bash_paths — no need to duplicate here

# Enable uv shell completion (optional, improves tab completion)
if command -v uv &> /dev/null; then
    eval "$(uv generate-shell-completion bash 2>/dev/null || true)"
fi