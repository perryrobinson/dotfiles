# Dotfiles Refactor: Stow-Based Multiplatform Design

**Date:** 2026-03-29
**Status:** Approved
**Branch:** `refactor/stow-multiplatform`

## Context

This dotfiles repo has served as a developer environment setup for Debian/Ubuntu systems using bash. The owner is migrating their personal PC from Windows 10 to CachyOS (Arch-based) and needs the repo to support both Debian-based systems (for work, VMs, containers) and Arch-based systems (personal desktop). CachyOS is a superset of the dev setup — it includes everything the Debian profile has, plus desktop environment configs, hardware fixes, and system-level customizations.

A separate repo (`cachyos-setup`) exists as a migration journal and documentation repository. It is not a dotfiles repo — configs discovered during migration will move into this repo once validated. `cachyos-setup` keeps the docs, troubleshooting guides, and hardware notes.

Zsh support is explicitly out of scope. The design accommodates adding it later (the slot exists), but no zsh config will be built in this phase.

## Core Principles

1. **Stow-based file management.** Every config is a GNU Stow package. `stow <package>` is how configs get installed. No custom symlink/copy logic for config files.
2. **Profiles, not conditionals.** Instead of if/else distro detection scattered through scripts, you pick a profile: `debian-dev`, `arch-dev`, `cachyos-desktop`. Each profile is a plain text file listing which Stow packages to install and which setup scripts to run.
3. **Scripts stay for what Stow can't do.** Installing system packages, building tools from source, generating SSH keys. Stow handles file placement; scripts handle everything else.

## Repository Structure

```
dotfiles/
  # ── Stow packages (each mirrors ~ as root) ──────────

  # Shell config
  bash/                     # .bashrc, .bash_aliases, .bash_functions,
                            # .bash_paths, .bash_logger

  # Shared tool configs (shell-agnostic, stow on any system)
  nvim/                     # .config/nvim/
  tmux/                     # .tmux.conf
  git/                      # .gitconfig (base config, no user-specific data)

  # Per-tool shell integration (replaces current tool_configs/ directory)
  toolconfig-node/          # .tool_configs/node.sh
  toolconfig-python/        # .tool_configs/python.sh
  toolconfig-rust/          # .tool_configs/rust.sh
  toolconfig-java/          # .tool_configs/java.sh
  toolconfig-golang/        # .tool_configs/golang.sh
  toolconfig-bun/           # .tool_configs/bun.sh
  toolconfig-nvim/          # .tool_configs/nvim.sh

  # CachyOS desktop (stow on personal PC only)
  kde/                      # .config/kde*, .local/share/plasma, etc.
  pipewire/                 # .config/wireplumber/
  hardware/                 # .config/systemd/user/, .local/bin/fix-*.sh

  # ── Not Stow packages ──────────────────────────────

  scripts/
    install.sh              # Orchestrator: detect/select profile → packages → scripts → stow
    setup_node.sh
    setup_python.sh
    setup_rust.sh
    setup_java.sh
    setup_golang.sh
    setup_bun.sh
    setup_nvim.sh
    setup_git.sh
    common.sh               # Shared helpers (bash_logger, distro detection)

  packages/
    debian-essentials.txt   # apt packages
    arch-essentials.txt     # pacman packages
    cachyos-desktop.txt     # full desktop packages (AUR included)

  profiles/
    debian-dev.txt          # stow packages + setup scripts for Debian work
    arch-dev.txt            # stow packages + setup scripts for Arch dev-only
    cachyos-desktop.txt     # everything — dev tools + desktop + hardware

  templates/
    bash_secrets.template   # secrets file, not tracked in git

  test/
    Dockerfile.debian       # Ubuntu-based test image
    Dockerfile.arch         # Arch-based test image
    run-test.sh

  docs/
    superpowers/specs/      # design docs (this file)
```

### Stow Package Layout

Each Stow package mirrors the home directory structure. Examples:

```
bash/
  .bashrc
  .bash_aliases
  .bash_functions
  .bash_paths
  .bash_logger

nvim/
  .config/
    nvim/
      init.lua
      lazy-lock.json
      lazyvim.json
      .neoconf.json
      stylua.toml

toolconfig-node/
  .tool_configs/
    node.sh

hardware/
  .config/
    systemd/
      user/
        logitech-audio-fix.service
  .local/
    bin/
      fix-logitech-audio.sh
      fix-mouse.sh
```

Running `stow bash` from the repo root creates symlinks: `bash/.bashrc` → `~/.bashrc`, etc. This requires the repo to be cloned at `~/dotfiles` (Stow targets the parent directory by default). Alternatively, `stow -t ~ bash` works from any location.

## Profile System

A profile is a plain text file. Comments and blank lines are ignored. Two sections separated by headers:

```
# Stow packages
bash
nvim
tmux
git
toolconfig-node
toolconfig-python

# Setup scripts
scripts/setup_git.sh
scripts/setup_node.sh
scripts/setup_python.sh
```

### Defined Profiles

**`profiles/debian-dev.txt`** — Work servers, VMs, containers:
- Stow: `bash`, `nvim`, `tmux`, `git`, all `toolconfig-*` packages
- Scripts: all `setup_*.sh` scripts
- Packages: `packages/debian-essentials.txt`

**`profiles/arch-dev.txt`** — Arch-based dev-only (no desktop):
- Same as `debian-dev` but uses `packages/arch-essentials.txt`

**`profiles/cachyos-desktop.txt`** — Full personal PC:
- Everything in `arch-dev`, plus `kde`, `pipewire`, `hardware`
- Packages: `packages/arch-essentials.txt` + `packages/cachyos-desktop.txt`

### install.sh Flow

1. Auto-detect distro from `/etc/os-release` (or accept `--profile <name>` flag)
2. Install system packages from the matching `packages/*.txt` file(s)
3. Prompt for optional tool setup scripts ("Install Java? y/n") — profile defines what's offered
4. Run selected setup scripts
5. `stow` each package listed in the profile
6. Create `~/.bash_secrets` from template if it doesn't exist
7. In CI mode (`DOTFILES_CI=1`): no prompts, runs everything in the profile

## Shell Strategy

Bash is the only shell in scope. The existing modular sourcing chain is preserved:

```
.bashrc → .bash_aliases
        → .bash_functions
        → .bash_paths
        → .bash_secrets (not tracked)
        → .tool_configs/*.sh (loop)
```

Tool config files (`.tool_configs/*.sh`) use portable syntax — `export`, `PATH` additions, and simple conditionals. Where shell-specific features are needed (completions, lazy-loading), files detect the shell:

```sh
if [ -n "$BASH_VERSION" ]; then
  # bash completions
fi
```

This detection is forward-compatible with a future zsh Stow package that sources the same `~/.tool_configs/` directory. When zsh is added later, most tool_config files will work without changes.

## Testing Strategy

### Docker Test Targets

**Debian (`test/Dockerfile.debian`):**
- Ubuntu base image (existing, updated)
- Runs `install.sh` with `debian-dev` profile
- `DOTFILES_CI=1` for non-interactive mode

**Arch (`test/Dockerfile.arch`):**
- `archlinux:base` image
- Runs `install.sh` with `arch-dev` profile
- `DOTFILES_CI=1` for non-interactive mode

### What Gets Tested

- Stow packages create correct symlinks in `~`
- Setup scripts complete without error
- Tools are discoverable on PATH and report versions
- Shell config sources cleanly (`bash -l -c "echo ok"`)
- Profile system selects the right packages and scripts

### CI

GitHub Actions workflow with a matrix strategy — one job per Dockerfile. Runs on push and PR to main. Same pattern as the existing CI, extended to two targets.

The `cachyos-desktop` profile is not tested in CI. Desktop packages (KDE, pipewire, hardware services) require real hardware and a running display server. The `arch-dev` profile covers pacman compatibility and script correctness on Arch, which is the important part.

## Migration Path

Each step produces a working state. The repo is functional after every step.

### Step 1: Restructure into Stow packages
Move existing files into the Stow directory layout (e.g., `bash/bashrc` → `bash/.bashrc`). No new functionality — purely reorganization. Existing install method still works at this point alongside the new structure.

### Step 2: Replace symlink/copy logic with Stow
Simplify `install.sh` to use `stow` commands instead of custom symlink logic. Keep setup scripts unchanged. The backup-before-install behavior moves to a pre-stow check (Stow refuses to overwrite existing non-symlink files, so backup first).

### Step 3: Add profile system
Create `profiles/debian-dev.txt`. Wire `install.sh` to parse and execute profiles. At this point the Debian workflow works end-to-end with the new system.

### Step 4: Add Arch support
Create `packages/arch-essentials.txt`. Update setup scripts where they use apt-specific commands — centralize distro detection in `scripts/common.sh` and use it for package install commands. Create `profiles/arch-dev.txt`.

### Step 5: Add Arch Dockerfile + CI matrix
Create `test/Dockerfile.arch`. Update GitHub Actions to matrix strategy with both Debian and Arch jobs. Validate the Arch profile passes CI.

### Step 6: Add CachyOS desktop packages
Create `kde/`, `pipewire/`, `hardware/` Stow packages by migrating validated configs from `cachyos-setup`. Create `profiles/cachyos-desktop.txt` and `packages/cachyos-desktop.txt`. This step happens incrementally as each CachyOS component is tested and confirmed working on real hardware.

## Out of Scope

- **Zsh configuration.** The structure supports adding a `zsh/` Stow package later. Not built now.
- **NixOS or declarative system management.** CachyOS is the chosen distro.
- **cachyos-setup repo changes.** That repo stays as a migration journal and documentation archive.
- **VS Code config migration.** The existing `config/vscode/` content will be reorganized into a Stow package if needed, but is not a priority.
