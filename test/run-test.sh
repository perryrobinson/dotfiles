#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_NAME="dotfiles-test"

# Source bash_logger for styled output
source "$REPO_DIR/bash/bash_logger"

cleanup() { docker rmi -f "$IMAGE_NAME" 2>/dev/null || true; }
trap cleanup EXIT

log_header "Building test image"
docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile" "$REPO_DIR"

log_header "Running install"
docker run --name "${IMAGE_NAME}-run" \
    -e DOTFILES_CI=1 \
    "$IMAGE_NAME" \
    bash -c '
        cd ~/dotfiles
        chmod +x install.sh tools/*.sh
        ./install.sh
    '

# Commit the installed state so smoke tests run against it
log_info "Committing installed container state"
docker commit "${IMAGE_NAME}-run" "${IMAGE_NAME}:installed" >/dev/null
docker rm "${IMAGE_NAME}-run" >/dev/null

log_header "Running smoke tests"
docker run --rm -e DOTFILES_CI=1 "${IMAGE_NAME}:installed" bash -c '
    set -euo pipefail

    # Source bash_logger inside the container
    source ~/dotfiles/bash/bash_logger

    FAIL=0

    check() {
        local desc="$1"; shift
        if "$@" >/dev/null 2>&1; then
            log_success "$desc"
        else
            log_error "$desc"
            FAIL=1
        fi
    }

    # Source tool configs the same way bashrc does (without interactive guard)
    # Disable strict mode: third-party scripts (SDKMAN, nvm) use unbound
    # variables and have commands that return non-zero during init
    set +eu
    source ~/.bash_paths 2>/dev/null || true
    for f in ~/.tool_configs/*.sh; do
        [ -f "$f" ] && source "$f"
    done
    set -eu

    log_section "Symlinks"
    check "~/.bashrc is a symlink"       test -L ~/.bashrc
    check "~/.bash_aliases is a symlink"  test -L ~/.bash_aliases
    check "~/.tmux.conf is a symlink"     test -L ~/.tmux.conf

    log_section "Tools on PATH"
    check "node is on PATH"    command -v node
    check "npm is on PATH"     command -v npm
    check "npx is on PATH"     command -v npx
    check "java is on PATH"    command -v java
    check "python3 is on PATH" command -v python3
    check "go is on PATH"      command -v go
    check "rustc is on PATH"   command -v rustc
    check "bun is on PATH"     command -v bun
    check "nvim is on PATH"    command -v nvim
    check "pnpm is on PATH"    command -v pnpm
    check "uv is on PATH"      command -v uv

    log_section "Tools actually work"
    check "node runs"    node --version
    check "npm runs"     npm --version
    check "python3 runs" python3 --version
    check "go runs"      go version
    check "rustc runs"   rustc --version
    check "java runs"    java -version
    check "bun runs"     bun --version
    check "pnpm runs"    pnpm --version
    check "uv runs"      uv --version

    log_section "Node visible to subprocesses"
    check "node found by env"  env which node
    check "node works in bash -c" bash -c "node --version"

    if [ "$FAIL" -ne 0 ]; then
        log_error "SMOKE TESTS FAILED"
        exit 1
    fi
    log_success "ALL SMOKE TESTS PASSED"
'

docker rmi -f "${IMAGE_NAME}:installed" 2>/dev/null || true
log_header "Done"
