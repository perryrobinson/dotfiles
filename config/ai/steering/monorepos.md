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

- Prefer a single command runner as the front door when a repo provides one, especially `just`.
- In mixed-language repos, prefer workspace-aware commands over per-package ad hoc installs.
- Prefer affected-project checks when the repo supports them through Nx, Turborepo (`--filter='[HEAD]'`), or similar tooling.
- In pnpm TypeScript workspaces, use Turborepo as the task runner unless the repo already uses Nx or `just`. See `typescript.md` for the standard setup.
- Respect project graph metadata, target dependencies, and generated-code outputs before changing build orchestration.
- In uv Python workspaces, use `just` with `uv run` as the front door and `uv add --package <member>` for dependencies. See `python.md` for the standard setup.
- In polyglot repos, `just` is the human interface and the default scaffold is Nx-free: pnpm workspaces plus Turborepo for TypeScript, a uv workspace for Python, and `just` recipes that call both. See "Nx or not" below and `polyglot-monorepo.md` for the full scaffold.
- If Nx is in use, it owns the project graph and targets; `just` recipes delegate to Nx. Never call `just` from inside an Nx target.
- See `github-actions.md` for the affected-detection CI pattern in both tiers.
- Use root workspace manifests as the source of truth for package manager and runtime versions.
- Do not introduce naming conventions from one repo into another repo unless the user explicitly asks for that convention.

## Nx or not

Default to no Nx. A new scaffold is pnpm workspaces + Turborepo (TypeScript), a uv workspace (Python), `just` as the front door, one `lefthook.yml`, and one CI workflow with path-based `detect`. It has no extra graph to configure or keep in sync.

Adopt Nx when two or more of these are true, not before:

- Go, Java, or other languages join the graph and need real project-to-project dependencies, not just path filters.
- About 10+ projects, or CI time is dominated by running unaffected work that path filters cannot narrow.
- Codegen outputs (protobuf, OpenAPI) feed projects in several languages and the order must be derived, not hand-written.
- You need module-boundary enforcement, generators, or one remote cache and affected graph across all languages.

Migrating later is cheap because `just` stays the interface: add `nx.json` and `project.json` targets that wrap the existing commands, point recipes at `nx run`/`nx affected`, and switch the CI `detect` job to `nx show projects --affected`. Do not add Nx to an existing repo that works without it unless the user asks.
