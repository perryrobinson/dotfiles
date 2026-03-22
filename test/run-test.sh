#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

IMAGE_NAME="dotfiles-test"
trap 'docker rmi "$IMAGE_NAME" 2>/dev/null || true' EXIT

docker build -f test/Dockerfile -t "$IMAGE_NAME" .
docker run --rm -e DOTFILES_CI=1 "$IMAGE_NAME" bash -c '
    set -euo pipefail
    cd ~/dotfiles
    chmod +x install.sh tools/*.sh
    ./install.sh

    echo "--- Smoke tests ---"
    source ~/.bash_paths
    for f in ~/.tool_configs/*.sh; do [[ -f "$f" ]] && source "$f"; done

    # Symlinks
    test -L ~/.bashrc
    test -L ~/.bash_aliases
    test -L ~/.tmux.conf

    # Dev tools
    command -v java
    command -v python3
    command -v node
    command -v bun
    command -v go
    command -v rustc
    command -v nvim

    echo "All smoke tests passed"
'
