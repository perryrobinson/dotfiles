---
title: GitHub Actions Steering
description: Current action versions, pinning policy, and reusable workflow patterns (least-privilege permissions, full checks, composite toolchain setup, PR-title checks, release automation, Dependabot).
applies_when:
  - Creating or editing .github/workflows or .github/actions
  - Bumping GitHub Action versions
  - CI pipeline design for single or polyglot repos
  - Release automation or Dependabot configuration
tags:
  - github-actions
  - ci
  - release-please
  - dependabot
  - nx
  - lefthook
---

# GitHub Actions Steering

## Current versions

Verified against the GitHub releases API on 2026-10-08. Write the SHA with the release in a trailing comment (`uses: actions/checkout@3d3c42e... # v7.0.1`) in new workflows. This table goes stale; before relying on it in a later session, re-resolve each row with `t=$(gh api repos/<owner>/<repo>/releases/latest --jq .tag_name); gh api repos/<owner>/<repo>/commits/$t --jq .sha`.

| Action | Major | Latest release | Pin (full SHA of that release) |
| --- | --- | --- | --- |
| `actions/checkout` | `v7` | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| `actions/setup-node` | `v7` | v7.1.0 | `949feb2413d6458794dcd2491c4babbbce0c15c1` |
| `actions/setup-go` | `v7` | v7.0.0 | `b7ad1dad31e06c5925ef5d2fc7ad053ef454303e` |
| `actions/setup-java` | `v6` | v6.0.1 | `de7274f081f381c8f8158605e0321c36c376e2e6` |
| `actions/cache` | `v6` | v6.1.0 | `55cc8345863c7cc4c66a329aec7e433d2d1c52a9` |
| `actions/upload-artifact` | `v7` | v7.0.2 | `cf430e030ddbb5b0abf93d22962f4752f3646cd9` |
| `actions/download-artifact` | `v8` | v8.0.2 | `9000827ccba6bdab643e8b6fd33ac0654aef8333` |
| `pnpm/action-setup` | `v6` | v6.1.0 | `ea17c68df8912ef543352723c149a84f56e3d413` |
| `astral-sh/setup-uv` | `v10` | v10.2.0 | `c18668ad3cf93ea998bef934396af7bb5c839dc7` |
| `docker/setup-buildx-action` | `v4` | v4.4.1 | `f87e5991a6d7451dcb8d9637bfbc97413f497069` |
| `docker/login-action` | `v4` | v4.6.0 | `dbcb813823bdd20940b903addbd779551569679f` |
| `docker/build-push-action` | `v7` | v7.4.0 | `c3c9e263c25d99ce0380d002d59b67737d91b0dc` |
| `docker/metadata-action` | `v6` | v6.2.0 | `dc802804100637a589fabce1cb79ff13a1411302` |
| `golangci/golangci-lint-action` | `v9` | v9.3.0 | `ba0d7d2ec06a0ea1cb5fa41b2e4a3ab91d21278a` |
| `bufbuild/buf-action` | `v1` | v1.6.0 | `85aebf73123b5c15fd5528aaecbf9129cddf7fa7` |
| `googleapis/release-please-action` | `v5` | v5.0.0 | `45996ed1f6d02564a971a2fa1b5860e934307cf7` |

Notes that affect how these are used:

- `pnpm/action-setup` reads the version from `packageManager`, so it takes no `version` input. Run it before `actions/setup-node` with `cache: pnpm`, because the cache step needs pnpm on the PATH.
- `actions/checkout` v6.1+ and v7 changed `pull_request_target` defaults (`allow-unsafe-pr-checkout`). Review any workflow that checks out PR code under `pull_request_target`.
- `astral-sh/setup-uv` takes `enable-cache: true` and `cache-dependency-glob: uv.lock`. v10 verifies downloads against known checksums and skips cache saves in merge queues.
- `golangci/golangci-lint-action` pins the linter with `version:`; use `install-only: true` when Nx or another runner invokes the binary.

## Bumping versions

1. Re-check the latest release of every action in the repo (`grep -rhn "uses:" .github | sort | uniq -c`).
2. Read the release notes of any major-version bump for breaking changes before editing.
3. Update every workflow and composite action together so no two files drift to different versions.
4. Run the affected workflows on a branch and confirm they pass before merging.

## Pinning

Pin every action to a full commit SHA with the release in a trailing comment, including `actions/*` and `docker/*`. Tags are mutable: a compromised or force-moved tag runs attacker code with your workflow's permissions (the tj-actions/changed-files incident), and GitHub's hardening guide recommends SHA pinning for all actions. `docker/*` is Docker's, not GitHub's, so it is third-party too. Resolve the SHA from a tag with:

```bash
gh api repos/<owner>/<repo>/commits/<tag> --jq .sha
```

```yaml
- uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
```

Pins only stay current if something updates them; see "Dependabot" below.

## Workflow hygiene

- Set `permissions: contents: read` at the top of every workflow, and widen per job only where needed (`packages: write`, `pull-requests: write`).
- Add a `concurrency` group with `cancel-in-progress: true` for PR workflows: `group: ci-${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}`. Use `cancel-in-progress: false` for scheduled or release jobs.
- Set `timeout-minutes` on jobs that can hang (smoke tests, integration, scheduled jobs).
- Pass untrusted values (PR titles, branch names, release notes, commit messages) into scripts through `env:`, then read them as shell variables. Never interpolate `${{ ... }}` of untrusted data into `run:` text.
- Install with the lockfile enforced: `pnpm install --frozen-lockfile`, `uv sync --locked`. Agents update lockfiles locally; CI only verifies.
- Gate expensive jobs with `needs`, so cheap checks (format, lint, types) fail first.
- Prefer `workflow_dispatch` inputs for costly optional jobs (full smoke, system tests) and a scheduled backstop that dispatches them when `main` changed.

## Polyglot monorepo pattern

The default in `polyglot-monorepo.md` uses one workflow with full TypeScript and Python jobs and one required gate. Run all checks/tests on every PR/push so fixture, asset, and shared-config changes are covered.

- **Composite action `.github/actions/setup-toolchains`:** takes string inputs (`node`, `python`, default `"false"`) and installs only the toolchain each job requests, plus its locked dependencies. Add other language inputs only when needed. This removes repeated setup without inventing a project graph.
- **Quality, test, integration, and codegen-drift jobs** run package scripts or the repo's existing runner. Codegen-drift jobs regenerate and fail on any diff. Keep `just` as the local interface; CI can invoke the underlying commands directly.
- **Affected selection is optional:** add it only when full runs are costly. Use the existing dependency graph when available, and cover all files owned by each project, downstream consumers, fixtures/assets, and shared configuration. Unknown inputs must run checks rather than skip them. Test selection against real changes before making it a required gate; extension-only filters are insufficient.
- **Keep `push: main` validation** unless a merge queue or equivalent protection guarantees the merged result was tested. Publishing should consume verified outputs.

## PR title check

Put the Conventional Commits title check in its own workflow, with `pull_request` types `[opened, edited, synchronize, reopened]`, so editing a bad title re-triggers validation without a new commit. Keep `edited` out of the main CI workflow, where it would rerun the full suite on every description tweak. Read the title through `env:` and validate with a regex such as `^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([A-Za-z0-9._-]+\))?!?: .+`.

## Releases

- Use `googleapis/release-please-action` with `release-please-config.json` and `.release-please-manifest.json` so squash-merged Conventional Commits drive versions and changelogs per package.
- Build the release matrix from the action's outputs (`<path>--release_created`, `<path>--version`) and release images in a matrix job that `needs` the release job.
- Log in to `ghcr.io` with `${{ secrets.GITHUB_TOKEN }}`; gate pushes behind a repository variable (for example `vars.PUBLISH_IMAGES == 'true'`) so forks and dry runs build without publishing.

## Dependabot

Configure `.github/dependabot.yml` for every ecosystem the repo uses (`github-actions`, `npm`, `uv`, `maven`, `gomod`, `docker`, `docker-compose`).

- **Code dependencies** (`npm`, `uv`, `maven`, `gomod`, `docker`): `open-pull-requests-limit: 0`. That disables routine version-bump PRs, so dependency changes stay deliberate, and still lets Dependabot open security-advisory PRs.
- **`github-actions`:** a grouped monthly update (`schedule.interval: monthly`, `groups: {actions: {patterns: ["*"]}}`, `cooldown.default-days: 3`). SHA pins never move on their own, and security-only PRs do not cover an action that is simply majors behind, so this one ecosystem keeps routine updates on. One grouped PR a month is reviewable.
- **Commit messages:** `commit-message.prefix: chore` with `include: scope`, which yields `chore(deps): ...`. `deps` is not a Conventional Commits type, so it would not pass the PR-title check or appear in release-please changelogs.

## Git hooks: Lefthook only

Use Lefthook for every hook type; do not add the `pre-commit` framework to new repos. Lefthook runs the tools already in the repo (`pnpm oxlint`, `uv run ruff`) in parallel from one `lefthook.yml`, so TypeScript and Python jobs sit side by side in a polyglot repo. A repo that already uses `pre-commit` keeps it until migrated; do not run both.

Add these jobs next to the pre-commit jobs from `typescript.md` and `python.md`:

```yaml
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
      run: pnpm run check
```

`{1}` is the commit message file. The quality job above is for TypeScript; use `run: just check` in Python-only and polyglot repos, whose templates define that recipe. Do not reference `check-affected` unless the repo actually provides and verifies it. `lefthook install` registers all configured hooks; pnpm repos run it through `prepare`, while uv-only repos run `uv run lefthook install` through `just setup`. Verify pre-push from a normal shell on both a clean and deliberately broken feature branch. Keep the commit-msg regex in sync with the PR-title check.
