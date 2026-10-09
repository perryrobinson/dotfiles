---
title: GitHub Actions Steering
description: Current action versions, pinning policy, and reusable workflow patterns (least-privilege permissions, affected detection, composite toolchain setup, PR-title checks, release automation, Dependabot).
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

Verified against the GitHub releases API on 2026-10-08. Write the major tag (`@v7`) in new workflows. Before relying on this table in a later session, re-check with `gh api repos/<owner>/<repo>/releases/latest --jq .tag_name`; the table goes stale.

| Action | Use | Latest release |
| --- | --- | --- |
| `actions/checkout` | `@v7` | v7.0.1 |
| `actions/setup-node` | `@v7` | v7.1.0 |
| `actions/setup-go` | `@v7` | v7.0.0 |
| `actions/setup-java` | `@v6` | v6.0.1 |
| `actions/cache` | `@v6` | v6.1.0 |
| `actions/upload-artifact` | `@v7` | v7.0.2 |
| `actions/download-artifact` | `@v8` | v8.0.2 |
| `pnpm/action-setup` | `@v6` | v6.1.0 |
| `astral-sh/setup-uv` | `@v10` | v10.2.0 |
| `docker/setup-buildx-action` | `@v4` | v4.4.1 |
| `docker/login-action` | `@v4` | v4.6.0 |
| `docker/build-push-action` | `@v7` | v7.4.0 |
| `docker/metadata-action` | `@v6` | v6.2.0 |
| `golangci/golangci-lint-action` | `@v9` | v9.3.0 |
| `bufbuild/buf-action` | `@v1` | v1.6.0 |
| `googleapis/release-please-action` | `@v5` | v5.0.0 |

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

Pin third-party actions (anything outside `actions/*` and `docker/*`) to a full commit SHA with the version in a trailing comment. Resolve the SHA from a tag with:

```bash
gh api repos/<owner>/<repo>/commits/<tag> --jq .sha
```

```yaml
- uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
```

First-party `actions/*` and `docker/*` actions use the major tag.

## Workflow hygiene

- Set `permissions: contents: read` at the top of every workflow, and widen per job only where needed (`packages: write`, `pull-requests: write`).
- Add a `concurrency` group with `cancel-in-progress: true` for PR workflows: `group: ci-${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}`. Use `cancel-in-progress: false` for scheduled or release jobs.
- Set `timeout-minutes` on jobs that can hang (smoke tests, integration, scheduled jobs).
- Pass untrusted values (PR titles, branch names, release notes, commit messages) into scripts through `env:`, then read them as shell variables. Never interpolate `${{ ... }}` of untrusted data into `run:` text.
- Install with the lockfile enforced: `pnpm install --frozen-lockfile`, `uv sync --locked`. Agents update lockfiles locally; CI only verifies.
- Gate expensive jobs with `needs`, so cheap checks (format, lint, types) fail first.
- Prefer `workflow_dispatch` inputs for costly optional jobs (full smoke, system tests) and a scheduled backstop that dispatches them when `main` changed.

## Polyglot monorepo pattern

Pick the tier by the rules in `monorepos.md` ("Nx or not"). Both tiers share one CI workflow with a `detect` job, a composite toolchain-setup action, and a codegen-drift job.

- **`detect` job:** computes which parts changed and per-language flags (needs Python, Go, Java, buf). Check out with `fetch-depth: 0`. Downstream jobs run only for affected parts and install only the toolchains they need.
  - Default (no Nx): path filters (`dorny/paths-filter`, or `git diff --name-only <base>...HEAD` matched against `apps/*`, `packages/*`) set the flags; TypeScript jobs use `turbo run <task> --affected`; Python jobs run `just check`/`just test` when any Python path or `uv.lock` changed.
  - Nx tier: `nx show projects --affected --base=<ref> --withTarget <target> --json`.
- **Composite action `.github/actions/setup-toolchains`:** takes boolean inputs (`python`, `go`, `java`, `buf`) and installs Node and pnpm always, then uv, Go, golangci-lint, buf, and Java conditionally. This removes the repeated setup preamble across jobs. Use `go-version-file: go.work` and `cache-dependency-path: '**/go.sum'` for Go, `cache: maven` for Java, and `GOTOOLCHAIN=auto` when `go.work` declares a toolchain.
- **Quality, test, integration, and codegen-drift jobs** run `just` recipes (default) or Nx targets (`nx affected -t check`, `-t test`) against the detected base. Codegen-drift jobs regenerate and fail on any diff.
- **Skip redundant post-merge runs:** when branch protection requires PRs to be up to date and green (or a merge queue is on), a push to `main` re-runs nothing except publishing.

## PR title check

Put the Conventional Commits title check in its own workflow, with `pull_request` types `[opened, edited, synchronize, reopened]`, so editing a bad title re-triggers validation without a new commit. Keep `edited` out of the main CI workflow, where it would rerun the full suite on every description tweak. Read the title through `env:` and validate with a regex such as `^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|deps)(\([A-Za-z0-9._-]+\))?!?: .+`.

## Releases

- Use `googleapis/release-please-action` with `release-please-config.json` and `.release-please-manifest.json` so squash-merged Conventional Commits drive versions and changelogs per package.
- Build the release matrix from the action's outputs (`<path>--release_created`, `<path>--version`) and release images in a matrix job that `needs` the release job.
- Log in to `ghcr.io` with `${{ secrets.GITHUB_TOKEN }}`; gate pushes behind a repository variable (for example `vars.PUBLISH_IMAGES == 'true'`) so forks and dry runs build without publishing.

## Dependabot

Configure `.github/dependabot.yml` for every ecosystem the repo uses (`github-actions`, `npm`, `uv`, `maven`, `gomod`, `docker`, `docker-compose`) with `open-pull-requests-limit: 0`. That disables routine version-bump PRs, so pins stay deliberate, and still lets Dependabot open security-advisory PRs. Set `commit-message.prefix: deps` so those PRs pass the PR-title check, and add `deps` to the allowed types.

## Git hooks: Lefthook only

Use Lefthook for every hook type; do not add the `pre-commit` framework to new repos. Lefthook runs the tools already in the repo (`pnpm oxlint`, `uv run ruff`) in parallel from one `lefthook.yml`, so TypeScript and Python jobs sit side by side in a polyglot repo. A repo that already uses `pre-commit` keeps it until migrated; do not run both.

Add these jobs next to the pre-commit jobs from `typescript.md` and `python.md`:

```yaml
commit-msg:
  jobs:
    - name: conventional-commit
      run: grep -Eq '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([A-Za-z0-9._-]+\))?!?: .+' {1} || { echo "Commit message must follow Conventional Commits"; exit 1; }

pre-push:
  jobs:
    - name: no-push-from-main
      run: test "$(git branch --show-current)" != main || { echo "Do not push from main"; exit 1; }
    - name: affected-checks
      run: just check-affected
```

`{1}` is the commit message file. `lefthook install` registers all hook types found in the file,; run it from the root `prepare` script in pnpm repos, or add a `setup` recipe (`lefthook install`) to the `justfile` in uv-only repos. Keep the commit-msg regex in sync with the PR-title check.
