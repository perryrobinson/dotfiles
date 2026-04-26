# Global Codex Guidance

## Working Agreements

- Read the repository before making assumptions, and follow existing patterns before introducing new ones.
- Keep edits scoped to the requested behavior. Avoid unrelated refactors and dependency churn.
- If the worktree already has changes, treat them as user work and do not revert them unless explicitly asked.
- Prefer small, reviewable changes with focused verification over broad rewrites.
- Commit frequently at discrete logical milestones when working on a branch.
- Use Conventional Commits for all commit messages, for example `feat: add user onboarding`, `fix: handle missing config`, or `docs: update setup notes`.

## Toolchains

- For TypeScript and JavaScript, prefer `pnpm` and respect pnpm workspaces.
- For browser SPAs, prefer Vite and TanStack Router unless the repository clearly uses another stack.
- Use nvm-managed Node versions. Check `.nvmrc`, `packageManager`, lockfiles, and workspace files before changing Node tooling.
- For Python, prefer `uv` for dependency management, virtual environments, scripts, and workspaces.
- For Java, use SDKMAN-managed Java, Maven, and Gradle when available.
- Use the repository's existing formatter, linter, test runner, and package manager rather than substituting equivalents.

## Docker and WSL

- This machine is WSL on Windows. Docker is expected to be provided by Docker Desktop on the Windows side.
- If Docker is unavailable from WSL, check whether Docker Desktop is running before concluding Docker is not installed.
- The tested WSL command to start Docker Desktop is `/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -Command "Start-Process -FilePath 'C:\Program Files\Docker\Docker\Docker Desktop.exe'"`.
- After starting Docker Desktop, poll with `docker ps` until the daemon is ready. If Codex sandboxing reports permission denied on `/var/run/docker.sock`, retry the Docker command with escalated permissions.
- If the WSL `docker` command is missing or broken, the tested Windows Docker CLI path is `/mnt/c/Program Files/Docker/Docker/resources/bin/docker.exe`.
- Docker Compose is also available from Windows at `/mnt/c/Program Files/Docker/Docker/resources/bin/docker-compose.exe`.
- Do not install Docker directly inside WSL unless explicitly asked. Some people use that setup, but this machine's default is Windows Docker Desktop with WSL integration.

## Verification

- Run the narrowest relevant formatter, typecheck, lint, and tests after code changes.
- If full verification is expensive or blocked, run the closest focused check and clearly state what did and did not run.
- Do not claim work is complete without fresh verification evidence from this machine.
