---
title: Polyglot Monorepo Steering
description: Lightweight default scaffold for a repo with TypeScript (pnpm) and Python (uv) together, without Nx. One justfile, one lefthook.yml, one CI workflow with change detection, and when to add Nx.
applies_when:
  - Creating a repo that has both pnpm TypeScript and uv Python packages
  - Adding Python to a pnpm workspace or TypeScript to a uv workspace
  - Merging TypeScript and Python tooling, hooks, or CI into one repo
  - Deciding whether a polyglot repo needs Nx
tags:
  - monorepo
  - polyglot
  - pnpm
  - uv
  - just
  - lefthook
  - turborepo
---

# Polyglot Monorepo Steering

This is the default scaffold for a repo that holds both TypeScript and Python. It has no Nx. `typescript.md` and `python.md` each describe a single-language repo with its own `lefthook.yml`, `ci.yml`, and `.gitignore`; applied side by side they collide. In a polyglot repo, take the per-language config files from those docs and use this doc for everything shared: the root manifests, `justfile`, `lefthook.yml`, `.gitignore`, and CI.

Move to Nx only when `monorepos.md` ("Nx or not") says the repo has outgrown this.

Verified in a scratch repo (pnpm 11, TypeScript 7.0, uv 0.11, Ruff 0.16, Pyrefly 1.3, Lefthook 2.2) with one TypeScript and two Python members built from the files in this doc: `pnpm install` and `uv sync` both succeed, `just check` and `just test` pass, a commit with a bad `.py` file is blocked by the Python jobs only (the TypeScript jobs do not start), a bad `.ts` file is blocked by the TypeScript jobs only, a non-conventional message is blocked by `commit-msg`, and a push from `main` is blocked. Also verified: the workflow files and composite action pass `actionlint`; the `detect` step's shell logic gives the right `ts`/`py` flags for docs-only, Python-only, TypeScript-only, `.github`, `pyproject.toml`-only, JSON-only, empty-base, and zero-SHA cases; `just check-affected` runs only the toolchains that changed; and type-aware lint fails on a clean checkout without `^build` and passes with it, with every task cached on a repeat run. The workflows have not run on GitHub, so the composite action's `if:` inputs and the `ci` gate job are untested at runtime. Problems found while verifying are fixed above: uv rejects glob members without a `pyproject.toml`, and oxfmt formats `pyproject.toml` unless ignored.

## Layout

```
package.json              # pnpm root (private): scripts, devDependencies, packageManager
pnpm-workspace.yaml       # packages + allowBuilds
pnpm-lock.yaml
turbo.json                # TypeScript tasks only
tsconfig.base.json  .oxlintrc.json  .oxfmtrc.json   # from typescript.md
pyproject.toml            # uv virtual root; Ruff, Pyrefly, pytest config   # from python.md
uv.lock  .python-version  .nvmrc
justfile                  # the human front door for both toolchains
lefthook.yml              # one file, both languages
.github/
  actions/setup-toolchains/action.yml
  workflows/ci.yml
apps/
  web/                    # package.json -> pnpm member
  api/                    # pyproject.toml -> uv member
packages/
  ui/                     # package.json
  core/                   # pyproject.toml (name it for its purpose; extract only when a second consumer needs it)
```

`apps/*` and `packages/*` hold both languages, and the manifest decides the toolchain. pnpm globs skip directories without a `package.json`, but uv errors on a glob match with no `pyproject.toml`, so list uv members explicitly (`members = ["apps/api", "packages/core"]`). Keep the two toolchains out of each other's way: a Python member never has a `package.json`, and a TypeScript member never has a `pyproject.toml`. If one deployable needs both (a Python API with a generated TypeScript client), make two members and let codegen connect them; see `codegen.md`.

## Root files

- **`package.json`, `pnpm-workspace.yaml`, `turbo.json`, `tsconfig.base.json`, `.oxlintrc.json`, `.oxfmtrc.json`:** exactly as in `typescript.md`. Turborepo only sees pnpm members, so Python code is invisible to it.
- **`pyproject.toml`:** exactly as in `python.md`, with two changes. Drop `lefthook` from the `dev` group (the pnpm root installs it), and list `[tool.uv.workspace] members` explicitly instead of globbing. Adding a Python member now means one line in each of `members`, `[tool.uv.sources]`, the `dev` group, `known-first-party`, and Pyrefly's `search-path`.
- **`.oxfmtrc.json`:** add `"**/*.toml"` to `ignorePatterns`. oxfmt formats TOML, so without this it rewrites `pyproject.toml` and fails `format:check` on the Python manifests. Ruff owns Python; oxfmt owns the TypeScript tree.
- **`.gitignore`:** see below. oxfmt and oxlint honor it, so ignoring `.venv` and `.turbo` there keeps both tools out of them.

```
node_modules
dist
.turbo
.venv
__pycache__
.pytest_cache
.ruff_cache
```

## `justfile`

`just` is the interface for people and agents. It calls the toolchains directly; it does not call Nx.

```just
default:
    @just --list

setup:
    pnpm install
    uv sync --locked

fmt:
    pnpm run format
    uv run ruff format .
    uv run ruff check --fix .

check: check-ts check-py

check-ts:
    pnpm run check:toolchain
    pnpm run typecheck
    pnpm run lint
    pnpm run format:check

check-py:
    uv run ruff format --check .
    uv run ruff check .
    uv run pyrefly check

test: test-ts test-py

test-ts:
    pnpm run test

test-py *args:
    uv run pytest {{args}}

# Pre-push: only the toolchains whose files changed against origin/main.
check-affected:
    #!/usr/bin/env bash
    set -euo pipefail
    # TURBO_SCM_BASE is required below: turbo --affected defaults to a local `main` branch and, when
    # that is missing or stale (feature branches, fresh clones), silently runs every package.
    files=$(git diff --name-only origin/main...HEAD)
    if grep -Eq '\.(py)$|pyproject\.toml$|^uv\.lock$' <<<"$files"; then just check-py; fi
    if grep -Eq '\.(ts|tsx|js|jsx|json|css)$|^pnpm-|turbo\.json$' <<<"$files"; then TURBO_SCM_BASE=origin/main pnpm exec turbo run typecheck lint --affected; fi
```

`just setup` is the one command after clone. `pnpm install` runs the root `prepare` script, which installs the git hooks, so no separate hook step exists.

## `lefthook.yml`

One file for both languages. Each job has a `glob`, so a commit that touches only Python never starts the TypeScript tools.

```yaml
pre-commit:
  parallel: true
  jobs:
    - name: format-ts
      glob: "*.{ts,tsx,js,jsx,json,jsonc,css}"
      run: pnpm oxfmt --no-error-on-unmatched-pattern {staged_files}
      stage_fixed: true
    - name: lint-ts
      glob: "*.{ts,tsx,js,jsx}"
      run: pnpm oxlint --max-warnings 0 {staged_files}
    - name: typecheck-ts
      glob: "*.{ts,tsx,json}"
      run: pnpm turbo run typecheck --filter='[HEAD]'
    - name: format-py
      glob: "*.py"
      run: uv run ruff format --force-exclude {staged_files}
      stage_fixed: true
    - name: lint-py
      glob: "*.py"
      run: uv run ruff check --force-exclude {staged_files}
    - name: typecheck-py
      glob: "*.py"
      run: uv run pyrefly check

commit-msg:
  jobs:
    - name: conventional-commit
      run: |
        grep -Eq '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([A-Za-z0-9._-]+\))?!?: .+' {1} || { echo "Commit message must follow Conventional Commits"; exit 1; }

pre-push:
  jobs:
    - name: no-push-from-main
      run: test "$(git branch --show-current)" != main || { echo "Do not push from main"; exit 1; }
    - name: affected-checks
      run: just check-affected
```

Lefthook is the only hook manager here; do not add `pre-commit`.

## CI

One workflow, one cheap `detect` job, and one gate job. Jobs for a toolchain are skipped when none of its files changed.

`.github/actions/setup-toolchains/action.yml`:

```yaml
name: Setup toolchains
description: Install the requested toolchains and their locked dependencies.
inputs:
  node:
    default: "false"
  python:
    default: "false"
runs:
  using: composite
  steps:
    - if: inputs.node == 'true'
      uses: pnpm/action-setup@ea17c68df8912ef543352723c149a84f56e3d413 # v6.1.0
    - if: inputs.node == 'true'
      uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
      with:
        node-version-file: .nvmrc
        cache: pnpm
    - if: inputs.node == 'true'
      shell: bash
      run: pnpm install --frozen-lockfile
    - if: inputs.python == 'true'
      uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
      with:
        enable-cache: true
    - if: inputs.python == 'true'
      shell: bash
      run: uv sync --locked
```

`.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read

concurrency:
  group: ci-${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

env:
  TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
  TURBO_TEAM: ${{ vars.TURBO_TEAM }}

jobs:
  detect:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    outputs:
      ts: ${{ steps.changes.outputs.ts }}
      py: ${{ steps.changes.outputs.py }}
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          fetch-depth: 0
      - id: changes
        env:
          BASE: ${{ github.event.pull_request.base.sha || github.event.before }}
        run: |
          ts=true; py=true
          if [ -n "$BASE" ] && git cat-file -e "$BASE^{commit}" 2>/dev/null; then
            files=$(git diff --name-only "$BASE" HEAD)
            ts=false; py=false
            grep -Eq '\.(ts|tsx|js|jsx|mjs|cjs|json|jsonc|css)$|^pnpm-|^\.nvmrc$' <<<"$files" && ts=true
            grep -Eq '\.py$|pyproject\.toml$|^uv\.lock$|^\.python-version$' <<<"$files" && py=true
            grep -Eq '^\.github/' <<<"$files" && { ts=true; py=true; }
          fi
          echo "ts=$ts" >> "$GITHUB_OUTPUT"
          echo "py=$py" >> "$GITHUB_OUTPUT"

  ts:
    needs: detect
    if: needs.detect.outputs.ts == 'true'
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: ./.github/actions/setup-toolchains
        with:
          node: "true"
      - run: pnpm run check:toolchain
      - run: pnpm run typecheck
      - run: pnpm run lint
      - run: pnpm run format:check
      - run: pnpm run build
      - run: pnpm run test

  py:
    needs: detect
    if: needs.detect.outputs.py == 'true'
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: ./.github/actions/setup-toolchains
        with:
          python: "true"
      - run: uv run ruff format --check .
      - run: uv run ruff check .
      - run: uv run pyrefly check
      - run: uv run pytest

  ci:
    if: always()
    needs: [detect, ts, py]
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - env:
          RESULTS: ${{ join(needs.*.result, ' ') }}
        run: |
          case " $RESULTS " in *" failure "*|*" cancelled "*) exit 1 ;; esac
```

- Make `ci` the only required status check in branch protection. A skipped `ts` or `py` job is neither a pass nor a fail for a required check, and the gate job turns "nothing to run" into a clean pass while any real failure still fails it.
- Skipped jobs are correct: a docs-only PR runs only `detect` and `ci`.
- `detect` treats an unknown base (first push, force-push, shallow history) as "everything changed". A false run is cheap; a false skip is not.
- `pnpm run build` and `test` need `^build` ordering, which Turborepo already handles. If the repo has many TypeScript packages, split `ts` into `check` and `build` jobs as in `typescript.md`.
- When Python work needs a database or other services, add that to the `py` job; do not move it into the shared composite action.

## Applying to a repo

1. Create the root `package.json`, `pnpm-workspace.yaml`, and `pyproject.toml` from `typescript.md` and `python.md`. Run `pnpm install` and `uv sync`; both must succeed with members from each language present.
2. Write the language configs (`tsconfig.base.json`, `.oxlintrc.json`, `.oxfmtrc.json`, `turbo.json`, Ruff/Pyrefly/pytest tables) and make `pnpm run typecheck` and `uv run pyrefly check` pass on the first members.
3. Write `justfile`; confirm `just check` and `just test` pass.
4. Write `lefthook.yml`; run `pnpm install` to register the hooks. The very first commit in a new repo has no `HEAD` for turbo's `--filter='[HEAD]'` to compare against, so make it with `git commit --no-verify` once. Make one broken `.ts` commit and one broken `.py` commit and confirm each is blocked by its own job only.
5. Write the composite action and `ci.yml`; confirm a TypeScript-only PR runs `ts` but skips `py`, and the reverse.
6. Set the `ci` job as the single required check.

## Growing out of this scaffold

Add Nx when `monorepos.md` says so. The migration keeps `just` as the interface, replaces the `detect` shell step with `nx show projects --affected`, and wraps the existing commands as Nx targets. Do not add Go or Java to this scaffold by copying the TypeScript pattern; at that point the project graph is the problem Nx exists to solve.
