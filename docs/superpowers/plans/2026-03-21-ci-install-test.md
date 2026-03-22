# CI Install Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add GitHub Actions CI that runs the Docker-based install test on every PR, with a non-interactive mode for `confirm()`.

**Architecture:** A single env var `DOTFILES_CI=1` makes `confirm()` auto-accept defaults. `test/run-test.sh` uses plain `docker build`/`run` to install everything and run smoke tests. The GitHub Actions workflow just calls `run-test.sh`.

**Tech Stack:** Bash, Docker, GitHub Actions

**Spec:** `docs/superpowers/specs/2026-03-21-ci-install-test-design.md`

---

### Task 1: Add non-interactive flag to `confirm()`

**Files:**
- Modify: `bash/bash_logger:184-192`

- [ ] **Step 1: Add CI guard to `confirm()`**

Insert one line after the `local` declarations, before the `hint` line:

```bash
[[ "${DOTFILES_CI:-}" == "1" ]] && return $([[ "$default" == "y" ]] && echo 0 || echo 1)
```

The full function becomes:

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

- [ ] **Step 2: Verify the change works**

Run from the repo root:

```bash
# Should return 0 (success) — default is "y"
DOTFILES_CI=1 bash -c 'source bash/bash_logger; confirm "test?" "y"; echo $?'
# Expected output: 0

# Should return 1 (failure) — default is "n"
DOTFILES_CI=1 bash -c 'source bash/bash_logger; confirm "test?" "n"; echo $?'
# Expected output: 1

# Without DOTFILES_CI, should prompt normally (Ctrl+C to exit)
bash -c 'source bash/bash_logger; confirm "test?" "y"'
# Expected: shows yellow prompt, waits for input
```

- [ ] **Step 3: Commit**

```bash
git add bash/bash_logger
git commit -m "feat: add DOTFILES_CI flag to skip interactive confirm() prompts"
```

---

### Task 2: Rewrite `test/run-test.sh` and delete `docker-compose.yml`

**Files:**
- Rewrite: `test/run-test.sh`
- Delete: `test/docker-compose.yml`

- [ ] **Step 1: Rewrite `test/run-test.sh`**

Replace the entire file with:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

IMAGE_NAME="dotfiles-test"

docker build -f test/Dockerfile -t "$IMAGE_NAME" .
docker run --rm -e DOTFILES_CI=1 "$IMAGE_NAME" bash -c '
    set -euo pipefail
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

Key differences from old script:
- Uses `docker build` + `docker run` instead of `docker compose`
- Sets `DOTFILES_CI=1` via `-e` flag
- Sources `~/.bash_paths` and `~/.tool_configs/*.sh` directly (not `~/.bashrc`, which has an interactive guard)
- Includes inline smoke tests for symlinks and dev tools
- Cleans up the image at the end

- [ ] **Step 2: Delete `test/docker-compose.yml`**

```bash
rm test/docker-compose.yml
```

- [ ] **Step 3: Verify `test/run-test.sh` is executable**

```bash
chmod +x test/run-test.sh
```

- [ ] **Step 4: Commit**

```bash
git add test/run-test.sh
git rm test/docker-compose.yml
git commit -m "refactor: simplify test to plain docker, add smoke tests, drop compose"
```

---

### Task 3: Add GitHub Actions workflow

**Files:**
- Create: `.github/workflows/test.yml`

- [ ] **Step 1: Create the workflow file**

```bash
mkdir -p .github/workflows
```

Write `.github/workflows/test.yml`:

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

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/test.yml
git commit -m "ci: add GitHub Actions workflow for install test"
```

---

### Task 4: End-to-end local verification

- [ ] **Step 1: Run the full test locally**

```bash
./test/run-test.sh
```

Expected: Docker builds the container, install.sh runs non-interactively (all confirms auto-accept), smoke tests verify symlinks exist and all dev tools are on PATH. Ends with "All smoke tests passed".

If any `command -v` check fails, it means that tool's install script failed silently or its PATH setup isn't sourced correctly by `~/.bash_paths` or `~/.tool_configs/*.sh`. Debug by running the container interactively:

```bash
docker run --rm -it -e DOTFILES_CI=1 dotfiles-test bash
```

- [ ] **Step 2: Fix any issues found and re-run**

**Known risk:** Docker installation inside the container (`curl -fsSL https://get.docker.com | sh`) may fail because the container has no systemd. Since `install.sh` runs under `set -euo pipefail`, this would abort the entire install. If this happens, the fix is to guard the Docker install section with `[[ "${DOTFILES_CI:-}" != "1" ]]` or change its confirm default to `"n"`.

For any other issues (tool download timeouts, PATH not set correctly), fix the relevant file and re-run `./test/run-test.sh`.

- [ ] **Step 3: Final commit if any fixes were needed**

Stage only the specific files that were changed and commit.
