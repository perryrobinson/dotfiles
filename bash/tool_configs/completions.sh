#!/usr/bin/env bash
# Shell completions configuration

# Git completion (if available)
if [ -f /usr/share/bash-completion/completions/git ]; then
    source /usr/share/bash-completion/completions/git
elif [ -f /etc/bash_completion.d/git ]; then
    source /etc/bash_completion.d/git
fi

# Docker completion (if docker is installed)
if command -v docker &> /dev/null; then
    if [ -f /usr/share/bash-completion/completions/docker ]; then
        source /usr/share/bash-completion/completions/docker
    fi
fi

# Docker Compose completion (if docker-compose is installed)
if command -v docker-compose &> /dev/null; then
    if [ -f /usr/share/bash-completion/completions/docker-compose ]; then
        source /usr/share/bash-completion/completions/docker-compose
    fi
fi

# npm completion (if npm is available)
if command -v npm &> /dev/null; then
    if [ ! -f ~/.npm_completion ]; then
        npm completion > ~/.npm_completion 2>/dev/null || true
    fi
    [ -f ~/.npm_completion ] && source ~/.npm_completion
fi


# kubectl completion (if kubectl is installed)
if command -v kubectl &> /dev/null; then
    if [ ! -f ~/.kubectl_completion ]; then
        kubectl completion bash > ~/.kubectl_completion 2>/dev/null || true
    fi
    [ -f ~/.kubectl_completion ] && source ~/.kubectl_completion
fi