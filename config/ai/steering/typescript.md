---
title: TypeScript Steering
description: Opinionated defaults for TypeScript and JavaScript workspaces, the standard strict setup (tsconfig, oxlint, oxfmt, Turborepo, Lefthook, CI), app structure, SPAs, validation, data fetching, and generated TypeScript.
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

The same setup for every new pnpm TypeScript workspace: strict `tsc`, oxlint (type-aware), oxfmt, Lefthook, Turborepo. Write these files verbatim, then adjust only `paths`, `lib`, workspace globs, and package names. An existing repo keeps its own tools; add the missing pieces around them and match its config style.

Every check exits non-zero on any finding, because agents read exit codes. A warning that exits 0 reads as success. The configs below set every rule to `error`, and lint scripts pass `--max-warnings 0`.

Verified in a scratch workspace on pnpm 11 and TypeScript 7.0: `typecheck`, `lint` (type-aware), and `oxfmt --check` run and fail on bad code, the tsconfig flags below are accepted by TypeScript 7, and the Lefthook hook formats staged files, blocks a bad commit, and passes a clean one. `turbo --filter='[HEAD]'` was confirmed to select packages with staged and unstaged changes, a repeat `turbo run lint typecheck` was fully cached, and type-aware lint was confirmed to fail on a clean checkout without `^build` (false `no-unsafe-*` errors on a workspace import) and pass with it. The workflow file passes `actionlint` but has not run on GitHub.

### Install

```bash
pnpm add -D -w typescript@^7 oxlint oxlint-tsgolint oxfmt turbo lefthook
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
    "build": "turbo run build",
    "typecheck": "turbo run typecheck",
    "lint": "turbo run lint",
    "test": "turbo run test",
    "format": "oxfmt",
    "format:check": "oxfmt --check",
    "check:toolchain": "tsc --version | grep -q '^Version 7\\.'",
    "prepare": "lefthook install"
  }
}
```

`check:toolchain` fails when the resolved TypeScript is not 7.x; CI runs it first. Run `pnpm run lint`, not `pnpm lint`, when a shell wrapper rewrites bare `pnpm <script>` calls.

### Package `package.json` scripts

Each package defines the tasks Turborepo runs. Dev dependencies, including `typescript`, live at the root only, so every package uses one TypeScript version and calls the binaries directly. Do not add `typescript` to a package's own `devDependencies`.

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

`oxfmt` writes in place; `oxfmt --check` exits non-zero on any diff. oxfmt also honors `.gitignore`. Formatting runs automatically in pre-commit, so it is never an agent task. `oxfmt --migrate=prettier` or `--migrate=biome` converts an existing config.

### `turbo.json` (root)

```json
{
  "$schema": "https://turborepo.dev/schema.json",
  "ui": "stream",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["$TURBO_DEFAULT$", "!**/*.md"],
      "outputs": ["dist/**", ".next/**", "!.next/cache/**"]
    },
    "typecheck": {
      "dependsOn": ["^build"],
      "inputs": [
        "src/**",
        "tests/**",
        "tsconfig.json",
        "package.json",
        "$TURBO_ROOT$/tsconfig.base.json"
      ],
      "outputs": []
    },
    "lint": {
      "dependsOn": ["^build"],
      "inputs": [
        "src/**",
        "tests/**",
        "tsconfig.json",
        "package.json",
        "$TURBO_ROOT$/.oxlintrc.json",
        "$TURBO_ROOT$/tsconfig.base.json"
      ],
      "outputs": []
    },
    "test": {
      "dependsOn": ["^build"],
      "outputs": ["coverage/**"]
    },
    "dev": { "cache": false, "persistent": true }
  }
}
```

- `^build` on `typecheck`, `lint`, and `test` gives each package built types from its dependencies. Type-aware lint resolves workspace imports the same way `tsc` does, so without it a clean checkout lints against missing types.
- Keep `inputs` precise. `inputs: ["**"]` defeats the cache, and cache hits are what keep an agent's repeated `typecheck` and `lint` runs near-instant.
- `ui: "stream"` keeps output as plain, ordered logs an agent can read; humans may switch to `"tui"` locally.
- Add `"$TURBO_ROOT$/<file>"` to a task's `inputs` whenever a root config file changes that task's result.

### `lefthook.yml` (root)

```yaml
pre-commit:
  parallel: true
  jobs:
    - name: format
      glob: "*.{ts,tsx,js,jsx,json,jsonc,css}"
      run: pnpm oxfmt --no-error-on-unmatched-pattern {staged_files}
      stage_fixed: true
    - name: oxlint
      glob: "*.{ts,tsx,js,jsx}"
      run: pnpm oxlint --max-warnings 0 {staged_files}
    - name: typecheck
      run: pnpm turbo run typecheck --filter='[HEAD]'
```

`--filter='[HEAD]'` typechecks only packages with changes since HEAD, including staged and unstaged edits, which keeps the hook fast in a large monorepo. A repo on Husky keeps Husky and adds the same filter to its hook. `lefthook install` runs through the root `prepare` script.

### `.gitignore` additions

```
node_modules
dist
.turbo
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

env:
  TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
  TURBO_TEAM: ${{ vars.TURBO_TEAM }}

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
      - name: Toolchain
        run: pnpm run check:toolchain
      - name: Type check
        run: pnpm run typecheck
      - name: Lint
        run: pnpm run lint
      - name: Format check
        run: pnpm run format:check

  build:
    needs: check
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
      - run: pnpm run build
      - run: pnpm run test
```

- Every action is pinned to a full commit SHA, per `github-actions.md`; that file holds the current pins.
- `pnpm/action-setup` reads the version from `packageManager`, so it needs no `version` input.
- Separate steps make a failure name its cause (type, lint, or format). `build` waits on `check` so broken code never burns build minutes.
- The two jobs repeat the setup preamble. In a repo with more jobs, move it into a composite action (see "Polyglot monorepo pattern" in `github-actions.md`).
- CI runs every package and relies on Turborepo's cache. To run only affected packages, use `turbo run <task> --affected` with `fetch-depth: 0` (a shallow clone makes everything count as changed) and `TURBO_SCM_BASE: origin/${{ github.base_ref }}` in `env`; `--affected` otherwise compares to a local `main`, and when that is missing it silently runs every package.
- Only CI uses `--frozen-lockfile`. Agents run plain `pnpm install` locally and commit the updated lockfile.
- `TURBO_TOKEN` and `TURBO_TEAM` enable remote caching and are optional.

### Applying to a repo

Run in this order; each step is verifiable before the next:

1. Install the dev dependencies, pin `packageManager`, and write `pnpm-workspace.yaml`, with `allowBuilds` for `lefthook`.
2. Write `tsconfig.base.json` and each package's `tsconfig.json`. Run `pnpm run typecheck` and fix every error. Strict flags on an existing codebase surface many.
3. Write `.oxlintrc.json` and the package `lint` scripts. Run `pnpm run lint`. Fix `no-explicit-any` and the `no-unsafe-*` errors first, since they cascade.
4. Write `.oxfmtrc.json`, run `pnpm run format`, then `pnpm run format:check`.
5. Write `turbo.json`; confirm a second `pnpm run typecheck` reports cache hits.
6. Write `lefthook.yml`, run `pnpm install` (the `prepare` script installs the hook), and make a deliberately broken commit to confirm the hook blocks it.
7. Write the CI workflow and confirm both jobs pass on a branch.

In a repo that also has Python, do not apply this file and `python.md` side by side. Use `polyglot-monorepo.md`, which merges the root manifest, hooks, and CI.
