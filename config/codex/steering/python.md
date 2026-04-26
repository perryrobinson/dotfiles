# Python Steering

- Use `uv` for dependency management, virtual environments, scripts, and workspaces.
- Prefer `uv run ...` over calling Python tools directly.
- Prefer `uv add`, `uv sync`, and `uv run --package <name> ...` over `pip`, manually managed virtualenvs, or direct `.venv` invocation.
- Use Ruff for linting and formatting when present.
- Use `ty` for typechecking when present.
- In uv workspaces, add dependencies to the owning package rather than the workspace root unless the dependency is genuinely shared tooling.
- Avoid relative imports in Python packages when the repo enforces absolute imports.
