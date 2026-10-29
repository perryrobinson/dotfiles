---
title: Polyglot Monorepo Steering
description: Lightweight default scaffold for a repo with TypeScript (pnpm) and Python (uv) together, without Nx. One justfile, one lefthook.yml, full CI checks, and when to add task orchestration.
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

Use `test/verify-ai-steering.py` for focused template checks. Before adopting the scaffold, verify a fresh workspace, clean and deliberately broken hooks, and fixture-only PRs. The example workflow has not run on GitHub.

## Layout

```
package.json              # pnpm root (private): scripts, devDependencies, packageManager
pnpm-workspace.yaml       # packages + allowBuilds
pnpm-lock.yaml
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

- **`package.json`, `pnpm-workspace.yaml`, `tsconfig.base.json`, `.oxlintrc.json`, `.oxfmtrc.json`:** as in the default `typescript.md` setup, using direct pnpm recursive scripts. No Turbo config is required.
- **`pyproject.toml`:** exactly as in `python.md`, with two changes. Drop `lefthook` from the `dev` group (the pnpm root installs it), and list `[tool.uv.workspace] members` explicitly instead of globbing. Adding a Python member now means one line in each of `members`, `[tool.uv.sources]`, the `dev` group, `known-first-party`, and Pyrefly's `search-path`.
- **`.oxfmtrc.json`:** add `"**/*.toml"` to `ignorePatterns`. oxfmt formats TOML, so without this it rewrites `pyproject.toml` and fails `format:check` on the Python manifests. Ruff owns Python; oxfmt owns the TypeScript tree.
- **`.gitignore`:** see below. oxfmt and oxlint honor it, so ignoring `.venv` and `node_modules` there keeps both tools out of them.

```
node_modules
dist
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
    pnpm run check

check-py:
    uv run ruff format --check .
    uv run ruff check .
    uv run pyrefly check

test: test-ts test-py

test-ts:
    pnpm run test

test-py *args:
    uv run pytest {{args}}

```

`just setup` is the one command after clone. `pnpm install` runs the root `prepare` script, which installs the git hooks, so no separate hook step exists.

## `lefthook.yml`

One file for both languages. Format first, then run complete checks. Full checks also catch fixture, asset, and shared-config edits without maintaining path filters.

```yaml
pre-commit:
  jobs:
    - name: format-ts
      glob: "*.{ts,tsx,js,jsx,json,jsonc,css}"
      run: pnpm oxfmt --no-error-on-unmatched-pattern {staged_files}
      stage_fixed: true
    - name: format-py
      glob: "*.py"
      run: uv run ruff format --force-exclude {staged_files}
      stage_fixed: true
    - name: checks
      run: just check

commit-msg:
  jobs:
    - name: conventional-commit
      run: |
        grep -Eq '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([A-Za-z0-9._-]+\))?!?: .+' {1} || { echo "Commit message must follow Conventional Commits"; exit 1; }

pre-push:
  jobs:
    - name: no-push-from-main
      run: test "$(git branch --show-current)" != main || { echo "Do not push from main"; exit 1; }
    - name: checks
      run: just check
```

Lefthook is the only hook manager here; do not add `pre-commit`.

## CI

One workflow runs both toolchains on every PR/push. This includes fixtures, assets, lockfiles, and shared configuration. Add change detection only if full checks become costly and project ownership/dependencies can be verified.

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

jobs:
  ts:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: ./.github/actions/setup-toolchains
        with:
          node: "true"
      - run: pnpm run check
      - run: pnpm run test

  py:
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
    needs: [ts, py]
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - env:
          RESULTS: ${{ join(needs.*.result, ' ') }}
        run: |
          test "$RESULTS" = "success success"
```

- Make `ci` the only required status check in branch protection. It passes only when both language jobs succeed; skipped, failed, or cancelled jobs fail the gate.
- Run both toolchains even for docs-only PRs at this scale. Fixture and shared-config changes cannot silently skip tests.
- `pnpm run check` builds dependency declarations before TypeScript and type-aware lint need them. The default test script also builds dependencies, so `just test` works independently.
- When Python work needs a database or other services, add that to the `py` job; do not move it into the shared composite action.

## Applying to a repo

1. Create the root `package.json`, `pnpm-workspace.yaml`, and `pyproject.toml` from `typescript.md` and `python.md`. Run `pnpm install` and `uv sync`; both must succeed with members from each language present.
2. Write the language configs (`tsconfig.base.json`, `.oxlintrc.json`, `.oxfmtrc.json`, Ruff/Pyrefly/pytest tables) and make `pnpm run check` and `uv run pyrefly check` pass on the first members.
3. Write `justfile`; confirm `just check` and `just test` pass.
4. Write `lefthook.yml`; run `pnpm install` to register the hooks. Confirm the first clean commit works without bypassing hooks, and that a broken TypeScript or Python change blocks a commit and pre-push.
5. Write the composite action and `ci.yml`; confirm both language jobs run, including for fixture-only and shared-config PRs, and either failure fails `ci`.
6. Set the `ci` job as the single required check.

## Growing out of this scaffold

Keep `just` as the interface. Add the optional Turbo setup from `typescript.md` when TypeScript caching saves meaningful time. Add Nx when cross-language dependencies, codegen ordering, or boundary enforcement need a project graph; see `monorepos.md`. More languages alone do not require a new runner. Preserve full CI coverage until any affected selection is verified against fixtures, shared configs, and downstream consumers.
