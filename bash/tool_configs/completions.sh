#!/usr/bin/env bash
# Extra shell completions not covered by the system bash-completion framework
# (git, docker, etc. are handled automatically via /usr/share/bash-completion)

# npm completion — generated once and cached
if command -v npm &> /dev/null; then
    if [ ! -f ~/.npm_completion ]; then
        npm completion > ~/.npm_completion 2>/dev/null || true
    fi
    [ -f ~/.npm_completion ] && source ~/.npm_completion
fi

# kubectl completion — generated once and cached
if command -v kubectl &> /dev/null; then
    if [ ! -f ~/.kubectl_completion ]; then
        kubectl completion bash > ~/.kubectl_completion 2>/dev/null || true
    fi
    [ -f ~/.kubectl_completion ] && source ~/.kubectl_completion
fi
