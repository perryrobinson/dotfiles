---
title: TypeScript Steering
description: Opinionated defaults for TypeScript and JavaScript workspaces, app structure, SPAs, Biome, validation, data fetching, and generated TypeScript.
applies_when:
  - TypeScript or JavaScript project changes
  - TypeScript project setup
  - pnpm workspace work
  - Vite or TanStack Router work
  - TanStack Query or Zod work
  - Biome linting or formatting
  - Generated TypeScript updates
tags:
  - typescript
  - javascript
  - pnpm
  - biome
  - vite
  - tanstack-router
  - tanstack-query
  - zod
---

# TypeScript Steering

- Prefer `pnpm` and respect pnpm workspaces.
- Prefer Vite and TanStack Router for browser SPAs unless the repository already uses another stack.
- Check `.nvmrc`, `packageManager`, lockfiles, and workspace files before changing Node tooling.
- Prefer strict TypeScript. Avoid `any`; model unknown data at boundaries and narrow it with validation.
- Use Biome for linting and formatting when present.
- Use the repo's TypeScript checker command. If the repo uses `tsgo`, keep using it.
- Prefer workspace filters such as `pnpm --filter <package> ...` for package-specific work.
- Prefer Bulletproof React-style feature organization for React apps: app providers/routing at the top, feature modules for product behavior, shared components/utilities for reusable primitives, and API clients isolated from UI components.
- Use TanStack Router for route structure and route-level data boundaries when building SPAs.
- Use TanStack Query for server-state fetching, caching, mutations, retries, and invalidation. Do not replace it with ad hoc `useEffect` fetch flows.
- Use Zod for runtime validation at external boundaries such as API responses, forms, URL/search params, environment/config, and local storage.
- Keep form, API, and domain DTO types explicit. Avoid letting component props become the only data model.
- Prefer modern CSS for new styling work unless the repo already uses a specific styling system.
- Keep generated clients and route artifacts separated from hand-written source when possible.
- Do not hand-edit generated route trees, generated API clients, or other generated TypeScript outputs. Regenerate them through the repo's codegen command.
