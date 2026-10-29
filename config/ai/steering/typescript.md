---
title: TypeScript Steering
description: Opinionated defaults for TypeScript and JavaScript workspaces, the standard strict setup (tsconfig, oxlint, oxfmt, Lefthook, CI) and optional Turborepo caching, app structure, SPAs, validation, data fetching, and generated TypeScript.
applies_when:
  - TypeScript or JavaScript project changes
  - TypeScript project setup
  - pnpm workspace work
  - Vite or TanStack Router work
  - TanStack Query or Zod work
  - oxlint or oxfmt configuration
  - Turborepo pipeline changes
  - Auditing or hardening TypeScript tooling (tsconfig, lint, hooks, CI)
  - Generated TypeScript updates
tags:
  - typescript
  - javascript
  - pnpm
  - oxc
  - oxlint
  - oxfmt
  - turborepo
  - lefthook
  - tsconfig
  - ci
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
- Use the oxc toolchain: oxlint for linting and oxfmt for formatting. In an existing repo on other tools (Biome, ESLint, Prettier), keep them unless asked to migrate.
- Lefthook is the only git hook manager. See `github-actions.md` for the `commit-msg` and `pre-push` jobs.
- Use TypeScript 7 or newer (`typescript@^7`) for new and migrated workspaces. `tsc` is the native compiler. Do not add `@typescript/native-preview` or `tsgo`, which it replaced. `oxlint-tsgolint` is built on typescript-go, so type-aware lint and `tsc` must agree on one set of semantics. A repo stuck on TypeScript 5 or 6 (for example because a tool still needs the JS compiler API) keeps it and records the reason in the repo.
- Prefer workspace filters such as `pnpm --filter <package> ...` for package-specific work.
- Prefer Bulletproof React-style feature organization for React apps: app providers/routing at the top, feature modules for product behavior, shared components/utilities for reusable primitives, and API clients isolated from UI components. Scale the structure to the app; a small SPA does not need every layer.
- Use TanStack Router for route structure and route-level data boundaries when building SPAs.
- Use TanStack Query for server-state fetching, caching, mutations, retries, and invalidation. Do not replace it with ad hoc `useEffect` fetch flows.
- Use Zod for runtime validation at external boundaries such as API responses, forms, URL/search params, environment/config, and local storage.
- Keep form, API, and domain DTO types explicit. Avoid letting component props become the only data model. Derive types from the Zod schema (`z.infer`) instead of hand-writing a parallel interface for the same shape.
- Prefer modern CSS for new styling work unless the repo already uses a specific styling system.
- Keep generated clients and route artifacts separated from hand-written source when possible.
- Do not hand-edit generated route trees, generated API clients, or other generated TypeScript outputs. Regenerate them through the repo's codegen command.

## Standard Setup

Start with package scripts, strict `tsc`, oxlint (type-aware), oxfmt, and Lefthook. Workspaces use pnpm recursive commands in dependency order; a single-package app calls the tools directly. Adapt package names, runtime/compiler options, and build/test commands to the project. Keep an existing repo's tools and config style. Add Turborepo only when repeated work is expensive enough to justify caching; see the optional section below.

Every check exits non-zero on any finding, because agents read exit codes. A warning that exits 0 reads as success. The configs below set every rule to `error`, and lint scripts pass `--max-warnings 0`.

Run the focused checks in `test/verify-ai-steering.py` after editing these templates. For adoption, also exercise a clean two-package workspace, the installed hooks, and the workflow on a branch. The example workflow has not run on GitHub.

### Install

```bash
pnpm add -D -w typescript@^7 oxlint oxlint-tsgolint oxfmt lefthook
```

The `^7` range keeps the workspace on the native compiler; a bare `typescript` would take whatever the lockfile already holds. `oxlint-tsgolint` provides the type-aware rules. pnpm 11 blocks dependency build scripts, so approve Lefthook's postinstall in `pnpm-workspace.yaml` (`allowBuilds`, below) or the hook never installs.

### Root `package.json`

Pin `packageManager` to the pnpm version in use (check `pnpm --version`).

```json
{
  "private": true,
  "type": "module",
  "packageManager": "pnpm@<current>",
  "scripts": {
    "build": "pnpm -r run build",
    "typecheck": "pnpm -r run typecheck",
    "lint": "pnpm -r run lint",
    "test": "pnpm run build && pnpm -r run test",
    "check": "pnpm run check:toolchain && pnpm run build && pnpm run typecheck && pnpm run lint && pnpm run format:check",
    "format": "oxfmt",
    "format:check": "oxfmt --check",
    "check:toolchain": "tsc --version | grep -q '^Version 7\\.'",
    "prepare": "lefthook install"
  }
}
```

`check:toolchain` fails when the resolved TypeScript is not 7.x; CI runs it first. Run `pnpm run lint`, not `pnpm lint`, when a shell wrapper rewrites bare `pnpm <script>` calls.

### Package `package.json` scripts

Each workspace package defines the scripts pnpm runs. The recursive commands exclude the root and run in dependency order. Dev dependencies, including `typescript`, live at the root only, so every package uses one TypeScript version and calls the binaries directly. Do not add `typescript` to a package's own `devDependencies`.

```json
{
  "scripts": {
    "typecheck": "tsc --noEmit",
    "lint": "oxlint --max-warnings 0 .",
    "build": "<bundler build>",
    "test": "<test runner>"
  }
}
```

Use `pnpm run check` on a clean checkout: it builds workspace dependencies before TypeScript and type-aware lint resolve imports from `dist/`. `test` also builds first. When calling `typecheck` or `lint` separately, run `pnpm run build` first if dependency declarations have not been built. For a single-package app, put the package scripts above at the root instead of the recursive scripts; keep `check`, formatting, the toolchain guard, and `prepare`.

### `pnpm-workspace.yaml`

```yaml
packages:
  - "packages/*"
  - "apps/*"
allowBuilds:
  lefthook: true
```

Add `"tooling/*"` to `packages` when shared configs live there.

### `tsconfig.base.json` (root, strict flags only)

No `include`, `exclude`, or `paths` here.

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "noFallthroughCasesInSwitch": true,
    "verbatimModuleSyntax": true,
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "target": "ES2022",
    "lib": ["ES2022"],
    "resolveJsonModule": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": false
  }
}
```

What each flag buys an agent's feedback loop:

- `noUncheckedIndexedAccess`: `arr[i]` is `T | undefined`, which catches off-by-one and missing-key bugs.
- `exactOptionalPropertyTypes`: an absent key differs from `undefined`.
- `noImplicitOverride`: base-class changes cannot silently break subclasses.
- `noPropertyAccessFromIndexSignature`: dynamic keys use bracket notation, which makes intent visible.
- `verbatimModuleSyntax`: enforces `import type` and supersedes `isolatedModules` on TS 5+.
- `skipLibCheck: false`: set `true` per package only when a dependency ships broken types and a local `.d.ts` augmentation cannot fix them.
- `moduleResolution: "Bundler"` suits Vite, Next, and tsup consumers. Use `module` and `moduleResolution` `NodeNext` for pure Node packages.

### Package `tsconfig.json`

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "noEmit": true,
    "lib": ["ES2022", "DOM", "DOM.Iterable"]
  },
  "include": ["src", "tests"]
}
```

Drop `lib` overrides for non-browser packages and add `"types": ["node"]` where Node globals are used. Extract a `tooling/tsconfig` package (`base.json`, `react-library.json`, `nextjs.json`) once 3+ packages repeat flags.

A package that emits output (a library other packages import) needs a separate build config, because TypeScript 7 requires an explicit `rootDir` for emit (`TS5011`) and the package config above sets `noEmit` and includes `tests`. Add `tsconfig.build.json` and point `build` at it:

```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": { "noEmit": false, "declaration": true, "rootDir": "src", "outDir": "dist" },
  "include": ["src"]
}
```

`"build": "tsc -p tsconfig.build.json"`, with `types` and `exports` in `package.json` pointing at `dist/`. Bundler-built packages (Vite, tsup) skip this.

To adopt strictness in an existing repo, create `tsconfig.check.json` that extends the current config with the new flags, fix its errors, then fold the flags into the main config.

### `.oxlintrc.json` (root)

```json
{
  "$schema": "./node_modules/oxlint/configuration_schema.json",
  "plugins": ["typescript", "unicorn", "import", "oxc"],
  "options": { "typeAware": true },
  "categories": { "correctness": "error", "suspicious": "error" },
  "rules": {
    "typescript/no-explicit-any": "error",
    "typescript/no-non-null-assertion": "error",
    "typescript/consistent-type-imports": "error",
    "typescript/no-floating-promises": "error",
    "typescript/no-misused-promises": "error",
    "typescript/await-thenable": "error",
    "typescript/require-await": "error",
    "typescript/no-unsafe-assignment": "error",
    "typescript/no-unsafe-member-access": "error",
    "typescript/no-unsafe-call": "error",
    "typescript/no-unsafe-return": "error",
    "typescript/no-unsafe-argument": "error",
    "typescript/no-unnecessary-type-assertion": "error",
    "eqeqeq": "error",
    "no-console": "error",
    "no-debugger": "error",
    "no-var": "error",
    "prefer-const": "error",
    "unicorn/prefer-node-protocol": "error",
    "unicorn/no-array-for-each": "error"
  },
  "overrides": [
    {
      "files": ["**/*.{test,spec}.{ts,tsx}", "**/tests/**"],
      "rules": {
        "typescript/no-explicit-any": "off",
        "typescript/no-non-null-assertion": "off",
        "typescript/no-unsafe-assignment": "off",
        "typescript/no-unsafe-call": "off",
        "no-console": "off"
      }
    }
  ],
  "ignorePatterns": ["**/dist/**", "**/build/**", "**/.next/**", "**/coverage/**", "**/*.gen.ts"]
}
```

For React packages, add the `react` plugin and `react/rules-of-hooks` as `error` (`react/exhaustive-deps` too, as `error`). Type-aware rules load the type checker, so they take seconds where plain oxlint takes milliseconds; that cost is why they live inside oxlint's single pass instead of a second ESLint run. A repo that already runs ESLint puts oxlint in front and leaves ESLint only the rules oxlint lacks.

### `.oxfmtrc.json` (root)

```json
{
  "$schema": "./node_modules/oxfmt/configuration_schema.json",
  "printWidth": 100,
  "semi": true,
  "singleQuote": false,
  "trailingComma": "all",
  "arrowParens": "always",
  "sortImports": {},
  "ignorePatterns": ["**/*.gen.ts", "pnpm-lock.yaml"]
}
```

`oxfmt` writes in place; `oxfmt --check` exits non-zero on any diff. oxfmt also honors `.gitignore`. The hook formats matching staged files; run `pnpm run format` for other formatter-supported files and initial setup. `oxfmt --migrate=prettier` or `--migrate=biome` converts an existing config.

### `lefthook.yml` (root)

```yaml
pre-commit:
  jobs:
    - name: format
      glob: "*.{ts,tsx,js,jsx,json,jsonc,css}"
      run: pnpm oxfmt --no-error-on-unmatched-pattern {staged_files}
      stage_fixed: true
    - name: checks
      run: pnpm run check
```

Run formatting before checks, without `parallel`, so lint/typecheck never race a first dependency build. The checks work before the first commit too. A repo on Husky keeps its hook manager and runs the same commands. `lefthook install` runs through the root `prepare` script. Add the shared `commit-msg`/branch guard from `github-actions.md`; the TypeScript pre-push quality job runs `pnpm run check`.

### `.gitignore` additions

```
node_modules
dist
```

### `.github/workflows/ci.yml`

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
  check:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: pnpm/action-setup@ea17c68df8912ef543352723c149a84f56e3d413 # v6.1.0
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version-file: .nvmrc
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - name: Checks (build dependencies, types, lint, formatting)
        run: pnpm run check
      - name: Tests
        run: pnpm run test
```

- Every action is pinned to a full commit SHA, per `github-actions.md`; that file holds the current pins.
- `pnpm/action-setup` reads the version from `packageManager`, so it needs no `version` input.
- Run all packages for every PR/push, including fixture, asset, and shared-config changes. Add affected selection only after full checks become costly and its coverage is verified.
- `check` builds packages before types and type-aware lint need their declarations. The default test script builds too, so it also works independently.
- Only CI uses `--frozen-lockfile`. Agents run plain `pnpm install` locally and commit the updated lockfile.

### Applying to a repo

Run in this order; each step is verifiable before the next:

1. Write the root/package manifests and `pnpm-workspace.yaml`, including `allowBuilds` for Lefthook, then install the dev dependencies and pin `packageManager`.
2. Write compiler, lint, and format configs and real package build/test scripts. Run `pnpm run format`, then `pnpm run check` and `pnpm run test`.
3. Verify from a clean two-package checkout that dependency builds finish before checks resolve workspace imports.
4. Write `lefthook.yml`, run `pnpm install` to register hooks, and confirm a deliberate lint/type error blocks a commit and pre-push. A clean feature branch must pass.
5. Write the CI workflow and confirm it passes on a branch, including a fixture-only change.

### Optional: Turborepo

Keep an existing useful Turbo setup. Add it to a new workspace when dependency-aware caching measurably saves time or task dependencies exceed pnpm's package ordering. A small app does not need it. Install `turbo` at the root and replace recursive task scripts with `turbo run <task>`; keep the root `check` interface. Add `.turbo` to `.gitignore`.

```json
{
  "$schema": "https://turborepo.dev/schema.json",
  "ui": "stream",
  "globalDependencies": ["tsconfig.base.json", ".oxlintrc.json"],
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["$TURBO_DEFAULT$"],
      "outputs": ["dist/**", ".next/**", "!.next/cache/**"]
    },
    "typecheck": { "dependsOn": ["^build"], "outputs": [] },
    "lint": { "dependsOn": ["^build"], "outputs": [] },
    "test": { "dependsOn": ["^build"], "outputs": ["coverage/**"] },
    "dev": { "cache": false, "persistent": true }
  }
}
```

- The default inputs include tracked package files, including declaration files, scripts, fixtures, and assets outside `src/`. Custom `inputs` replace these defaults; retain `$TURBO_DEFAULT$` when adding inputs. More complete inputs reduce cache hits but keep results correct.
- Root configs affect every package here, so `globalDependencies` invalidates all tasks when they change. Add other shared configs and environment inputs when tasks actually read them. Keep output patterns aligned with the build tool.
- `^build` gives typecheck, type-aware lint, and tests their dependencies' built declarations on a clean checkout.
- Verify both repeated-run cache hits and invalidation: change an included package-root `.d.ts`, a linted script outside `src/`, a root compiler config, and a test fixture. Each affected task must rerun and fail on deliberately bad input.
- Start with the full task set. If later adding `--affected`, configure and verify its Git base/history and dependent selection; do not use extension-only shell filters as a substitute for the dependency graph.

In a repo that also has Python, do not apply this file and `python.md` side by side. Use `polyglot-monorepo.md`, which merges the root manifest, hooks, and CI.
