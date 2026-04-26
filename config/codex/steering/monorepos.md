# Monorepo Steering

- Prefer a single command runner as the front door when a repo provides one, especially `just`.
- In mixed-language repos, prefer workspace-aware commands over per-package ad hoc installs.
- Prefer affected-project checks when the repo supports them through Nx or similar tooling.
- Respect project graph metadata, target dependencies, and generated-code outputs before changing build orchestration.
- Use root workspace manifests as the source of truth for package manager and runtime versions.
- Do not introduce naming conventions from one repo into another repo unless the user explicitly asks for that convention.
