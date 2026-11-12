---
title: Monorepo Steering
description: Opinionated defaults for workspace-oriented repositories and build orchestration.
applies_when:
  - Monorepo setup or maintenance
  - Nx, just, or workspace command changes
  - Cross-package checks or affected-project workflows
tags:
  - monorepo
  - polyglot
  - nx
  - just
  - workspaces
---

# Monorepo Steering

- For the command interface and recipe layout, read the [justfiles skill](../skills/justfiles/SKILL.md).
- In mixed-language repos, prefer workspace-aware commands over per-package ad hoc installs.
- Use full checks by default. Preserve an existing verified affected-project workflow; add one only when full checks become costly and dependency/fixture/config coverage is proven.
- In pnpm TypeScript workspaces, start with package scripts and pnpm recursive commands in dependency order. Keep a useful existing runner; add Turbo only when caching or task dependencies justify it. See `typescript.md`.
- Respect project graph metadata, target dependencies, and generated-code outputs before changing build orchestration.
- In uv Python workspaces, use `uv add --package <member>` for dependencies. See `python.md` for the standard setup.
- The default polyglot scaffold is Nx-free: pnpm workspaces and recursive package scripts for TypeScript, and a uv workspace for Python. See "Nx or not" below and `polyglot-monorepo.md` for the full scaffold.
- If Nx is in use, it owns the project graph and targets; `just` recipes delegate to Nx. Never call `just` from inside an Nx target.
- See `github-actions.md` for full CI coverage by default and requirements before optimizing with affected selection.
- Use root workspace manifests as the source of truth for package manager and runtime versions.
- Do not introduce naming conventions from one repo into another repo unless the user explicitly asks for that convention.

## Nx or not

Default to package scripts and native workspace commands. Run the full suite in CI. Keep an existing runner that works.

Add Turborepo when repeated TypeScript builds/checks are expensive enough for dependency-aware caching to save meaningful time, or task dependencies exceed pnpm's package ordering. Measure the benefit and verify invalidation before relying on the cache.

Choose Nx when the repo needs a cross-language project graph, derived codegen ordering, module-boundary enforcement, generators, or a shared affected/cache model. One concrete requirement can justify it; project count or another language alone is not a reason to migrate.

Keep the public command interface stable during a runner migration. Account for graph configuration and cache correctness as maintenance costs. Do not add a new runner to an existing repo that works without it unless the user asks.
