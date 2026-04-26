---
title: Python Steering
description: Opinionated defaults for Python projects, uv workspaces, package structure, APIs, dataframes, and shared packages.
applies_when:
  - Python project setup
  - Python package changes
  - Python API work
  - Dataframe or ETL work
  - Python shared package design
  - Python testing, linting, or typechecking
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
- Prefer uv workspaces for multi-package Python projects.
- Keep Python packages importable and explicit. Use `src` or package-root layouts already established by the repo, and avoid script-only architecture for application code.
- Use Ruff for linting and formatting when present.
- Use `ty` for typechecking when present.
- Treat linting, formatting, and typechecking as separate verification signals.
- In uv workspaces, add dependencies to the owning package rather than the workspace root unless the dependency is genuinely shared tooling.
- Use absolute imports for package structure. Avoid relative imports.
- Use `pytest` for tests unless the repo has standardized on another runner.
- Prefer async-capable tests for async code instead of hiding event-loop behavior behind sync wrappers.
- Use Polars when dataframe-style work is needed.
- Use FastAPI for Python APIs, served with Uvicorn or Gunicorn depending on the deployment shape.
- Keep FastAPI apps modular: app creation, routes, dependencies, settings, and persistence should not all live in one file once the project grows.
- Prefer Pydantic v2 models over dataclasses for validation, settings, DTOs, and structured API/domain boundaries.
- Use `pydantic-settings` or typed settings models for configuration. Avoid scattered direct environment lookups.
- Build a common/shared package early in Python projects for cross-cutting concerns such as logging, configuration, database connections, DTOs, and domain models.
- Prefer structured logging and shared logging setup over per-module ad hoc logger configuration.
- Keep database/session lifecycle management centralized in shared infrastructure code.
- Do not hand-edit generated Python protobuf, OpenAPI, or client outputs. Regenerate them through the repo's codegen command.
