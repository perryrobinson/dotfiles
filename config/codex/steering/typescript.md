---
title: TypeScript Steering
description: Opinionated defaults for TypeScript and JavaScript workspaces, SPAs, Biome, and generated TypeScript.
applies_when:
  - TypeScript or JavaScript project changes
  - pnpm workspace work
  - Vite or TanStack Router work
  - Biome linting or formatting
  - Generated TypeScript updates
tags:
  - typescript
  - javascript
  - pnpm
  - biome
  - vite
  - tanstack-router
---

# TypeScript Steering

- Prefer `pnpm` and respect pnpm workspaces.
- Prefer Vite and TanStack Router for browser SPAs unless the repository already uses another stack.
- Check `.nvmrc`, `packageManager`, lockfiles, and workspace files before changing Node tooling.
- Use Biome for linting and formatting when present.
- Use the repo's TypeScript checker command. If the repo uses `tsgo`, keep using it.
- Prefer workspace filters such as `pnpm --filter <package> ...` for package-specific work.
- Do not hand-edit generated route trees, generated API clients, or other generated TypeScript outputs. Regenerate them through the repo's codegen command.
