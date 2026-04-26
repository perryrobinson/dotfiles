# Global Codex Guidance

## Working Agreements

- Read the repository before making assumptions, and follow existing patterns before introducing new ones.
- Keep edits scoped to the requested behavior. Avoid unrelated refactors and dependency churn.
- If the worktree already has changes, treat them as user work and do not revert them unless explicitly asked.
- Prefer small, reviewable changes with focused verification over broad rewrites.

## Toolchains

- For TypeScript and JavaScript, prefer `pnpm` and respect pnpm workspaces.
- For browser SPAs, prefer Vite and TanStack Router unless the repository clearly uses another stack.
- Use nvm-managed Node versions. Check `.nvmrc`, `packageManager`, lockfiles, and workspace files before changing Node tooling.
- For Python, prefer `uv` for dependency management, virtual environments, scripts, and workspaces.
- For Java, use SDKMAN-managed Java, Maven, and Gradle when available.
- Use the repository's existing formatter, linter, test runner, and package manager rather than substituting equivalents.

## Verification

- Run the narrowest relevant formatter, typecheck, lint, and tests after code changes.
- If full verification is expensive or blocked, run the closest focused check and clearly state what did and did not run.
- Do not claim work is complete without fresh verification evidence from this machine.
