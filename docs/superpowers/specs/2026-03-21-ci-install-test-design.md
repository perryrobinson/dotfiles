# CI Install Test Design

## Problem

`install.sh` is interactive — the `confirm()` function in `bash/bash_logger` reads from `/dev/tty`, which fails in CI and non-interactive Docker contexts. This blocks automated testing of the full install flow.

## Solution

An opt-in `DOTFILES_CI=1` environment variable that makes `confirm()` auto-accept defaults instead of reading `/dev/tty`. Combined with a GitHub Actions workflow that builds a Docker container and runs the full install + smoke tests.

## Changes

### 1. `bash/bash_logger` — non-interactive flag (1 line added)

Add an early return to `confirm()` that checks `DOTFILES_CI`:

```bash
confirm() {
    local prompt="${1:-Continue?}" default="${2:-y}"
    [[ "${DOTFILES_CI:-}" == "1" ]] && return $([[ "$default" == "y" ]] && echo 0 || echo 1)
    local hint=$([[ "$default" == "y" ]] && echo "Y/n" || echo "y/N")

    echo -en "${_C_YELLOW}${_S_LINE} ${_S_WARN}  ${prompt} [${hint}] ${_C_RESET}"
    read -r response < /dev/tty
    [[ -z "$response" ]] && response="$default"
    [[ "$response" =~ ^[Yy]$ ]]
}
```

When `DOTFILES_CI=1`: returns 0 (success) if default is "y", returns 1 (failure) if default is "n". No TTY read, no prompt output. Works for all callers — `install.sh` and all `tools/setup_*.sh` scripts — since they all source `bash_logger` via `common.sh`.

All existing `confirm()` calls default to "y" (either explicitly or via the function's own default), so CI mode installs everything: symlinks, essential packages, Docker, all dev tools.

### 2. `test/run-test.sh` — rewritten

Replace the current `docker compose` approach with plain `docker build` + `docker run`. Sets `DOTFILES_CI=1` and includes inline smoke tests.

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

IMAGE_NAME="dotfiles-test"

docker build -f test/Dockerfile -t "$IMAGE_NAME" .
docker run --rm -e DOTFILES_CI=1 "$IMAGE_NAME" bash -c '
    cd ~/dotfiles
    chmod +x install.sh tools/*.sh
    ./install.sh

    echo "--- Smoke tests ---"
    source ~/.bash_paths
    for f in ~/.tool_configs/*.sh; do source "$f"; done

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
docker rmi "$IMAGE_NAME"
```

Note: smoke tests source `~/.bash_paths` and `~/.tool_configs/*.sh` directly instead of `~/.bashrc`, because bashrc has an interactive-shell guard (`case $- in *i*) ...`) that causes it to return early in non-interactive `bash -c` shells.

### 3. `test/docker-compose.yml` — deleted

No longer needed. The compose file only served `run-test.sh`, which now uses plain Docker commands. Removes the Docker Compose dependency from the test workflow.

### 4. `test/Dockerfile` — unchanged

The existing Dockerfile (Ubuntu 22.04, testuser with sudo, copies dotfiles in) works as-is. No modifications needed.

### 5. `.github/workflows/test.yml` — new file

```yaml
name: Test Install
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test-install:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run install test
        run: ./test/run-test.sh
```

CI just calls the same script used for local testing. One job, no matrix.

## Scope Notes

- The `DOTFILES_CI` flag is opt-in — normal interactive usage is unchanged.
- Docker installation inside the test container (via `get.docker.com`) should work — it installs packages without needing to start the daemon. If it fails in practice, we fix it then.
- SSH key generation in `setup_git.sh` auto-accepts in CI — creates a throwaway key in the disposable container.
- Smoke tests are simple shell assertions (`test -L`, `command -v`). No test framework.
