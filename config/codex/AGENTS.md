# Global Codex Guidance

## Working Agreements

- Read the repository before making assumptions, and follow existing patterns before introducing new ones.
- Keep edits scoped to the requested behavior. Avoid unrelated refactors and dependency churn.
- If the worktree already has changes, treat them as user work and do not revert them unless explicitly asked.
- Prefer small, reviewable changes with focused verification over broad rewrites.
- Commit frequently at discrete logical milestones when working on a branch, using Conventional Commits.

## Steering

Read these opinionated global steering docs only when the task touches the relevant area:

- Monorepos, Nx, and `just`: `~/dotfiles/config/codex/steering/monorepos.md`
- TypeScript, pnpm, Biome, Vite, and TanStack: `~/dotfiles/config/codex/steering/typescript.md`
- Python, uv, Ruff, and ty: `~/dotfiles/config/codex/steering/python.md`
- Go and protobuf tooling: `~/dotfiles/config/codex/steering/go.md`
- Java, SDKMAN, Maven, Gradle, and Checkstyle: `~/dotfiles/config/codex/steering/java.md`
- Git workflow and commits: `~/dotfiles/config/codex/steering/git.md`
- Testing and verification: `~/dotfiles/config/codex/steering/testing.md`
- Generated code: `~/dotfiles/config/codex/steering/codegen.md`
- Docker on WSL: `~/dotfiles/config/codex/steering/docker-wsl.md`
- Frontend application work: `~/dotfiles/config/codex/steering/frontend.md`

Do not read every steering doc by default. Steering docs include frontmatter; use `applies_when` and `tags` as routing hints. Direct user instructions and repo-local `AGENTS.md` files override these global docs.

## Toolchains

- Prefer repo-provided commands and existing toolchain choices over substituting equivalents.
- Use `uv` for Python work, `pnpm` for TypeScript and JavaScript work, and SDKMAN-managed Java tooling when Java is involved.

## Current Documentation

- Use Context7 MCP for current documentation when the user asks about a library, framework, SDK, API, CLI tool, or cloud service.
- Prefer Context7 over web search for API syntax, configuration, setup instructions, migrations, and library-specific debugging.
- Do not use Context7 for general programming concepts, business-logic debugging, code review, refactoring, or writing scripts from scratch.
- Start by resolving the library ID, choose the best matching source, then query docs with the user's full question. Use version-specific docs when the user names a version.

## Verification

- Run the narrowest relevant formatter, typecheck, lint, and tests after code changes.
- If full verification is expensive or blocked, run the closest focused check and clearly state what did and did not run.
- Do not claim work is complete without fresh verification evidence from this machine.
