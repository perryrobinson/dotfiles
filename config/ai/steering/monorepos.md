---
title: Monorepo Steering
description: Opinionated defaults for workspace-oriented repositories and build orchestration.
applies_when:
  - Monorepo setup or maintenance
  - Nx, just, or workspace command changes
  - Cross-package checks or affected-project workflows
tags:
  - monorepo
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
- In polyglot repos (Go, Java, Python, TypeScript), Nx owns the project graph and targets; `just` recipes are the human interface and delegate to Nx. Never call `just` from inside an Nx target. See `github-actions.md` for the affected-detection CI pattern.
- Use root workspace manifests as the source of truth for package manager and runtime versions.
- Do not introduce naming conventions from one repo into another repo unless the user explicitly asks for that convention.
