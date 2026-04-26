---
title: Python Steering
description: Opinionated defaults for Python projects, uv workspaces, APIs, dataframes, and shared packages.
applies_when:
  - Python project setup
  - Python package changes
  - Python API work
  - Dataframe or ETL work
  - Python shared package design
tags:
  - python
  - uv
  - ruff
  - ty
  - fastapi
  - pydantic
  - polars
---

# Python Steering

- Use `uv` for dependency management, virtual environments, scripts, and workspaces.
- Prefer `uv run ...` over calling Python tools directly.
- Prefer `uv add`, `uv sync`, and `uv run --package <name> ...` over `pip`, manually managed virtualenvs, or direct `.venv` invocation.
- Use Ruff for linting and formatting when present.
- Use `ty` for typechecking when present.
- In uv workspaces, add dependencies to the owning package rather than the workspace root unless the dependency is genuinely shared tooling.
- Use absolute imports for package structure. Avoid relative imports.
- Use Polars when dataframe-style work is needed.
- Use FastAPI for Python APIs, served with Uvicorn or Gunicorn depending on the deployment shape.
- Prefer Pydantic v2 models over dataclasses for validation, settings, DTOs, and structured API/domain boundaries.
- Build a common/shared package early in Python projects for cross-cutting concerns such as logging, configuration, database connections, DTOs, and domain models.
