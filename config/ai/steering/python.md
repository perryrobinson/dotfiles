---
title: Python Steering
description: Opinionated defaults for Python projects, the standard uv workspace setup (pyproject.toml, Ruff, Pyrefly, pytest, just, CI), package structure, APIs, dataframes, and shared packages.
applies_when:
  - Python project setup
  - Python package changes
  - Python API work
  - Dataframe or ETL work
  - Python shared package design
  - Python testing, linting, formatting, or typechecking
  - Python tooling audit or hardening (pyproject.toml, Ruff, Pyrefly)
tags:
  - python
  - uv
  - ruff
  - pyrefly
  - pytest
  - just
  - fastapi
  - pydantic
  - polars
---

# Python Steering

- Use `uv` for dependency management, virtual environments, scripts, and workspaces.
- Prefer `uv run ...` over calling Python tools directly.
- Prefer `uv add`, `uv sync`, and `uv run --package <name> ...` over `pip`, manually managed virtualenvs, or direct `.venv` invocation.
- Prefer uv workspaces for multi-package Python projects.
- Keep Python packages importable and explicit. Use `src` layout, and avoid script-only architecture for application code.
- Use Ruff for linting and formatting, and Pyrefly for typechecking. In an existing repo on other tools (mypy, pyright, ty), keep them unless asked to migrate.
- Treat linting, formatting, and typechecking as separate verification signals.
- Use absolute imports for package structure. Avoid relative imports.
- Use `pytest` for tests unless the repo has standardized on another runner.
- Prefer async-capable tests for async code instead of hiding event-loop behavior behind sync wrappers.
- Use Polars when dataframe-style work is needed.
- Use FastAPI for Python APIs, served with Uvicorn or Gunicorn depending on the deployment shape.
- Keep FastAPI apps modular: app creation, routes, dependencies, settings, and persistence should not all live in one file once the project grows.
- Use Pydantic v2 at I/O boundaries: API request/response models, settings, and parsing external data. Inside the domain layer, prefer `@dataclass(frozen=True, slots=True)` (or `attrs`) so construction pays no validation cost and the domain does not depend on a framework.
- Use `pydantic-settings` or typed settings models for configuration. Avoid scattered direct environment lookups.
- Extract a shared package when a second consumer needs the code, not before. Keep it narrow and name it for its purpose (`acme-logging`, `acme-settings`) rather than `common`, which becomes a dumping ground that every package depends on.
- Prefer structured logging and shared logging setup over per-module ad hoc logger configuration.
- Keep database/session lifecycle management centralized in shared infrastructure code.
- Do not hand-edit generated Python protobuf, OpenAPI, or client outputs. Regenerate them through the repo's codegen command.

## Standard Setup

Default setup for new multi-package Python projects: a uv workspace with a virtual root, `src` layout members, Ruff, Pyrefly (strict), pytest, and `just` as the front door. Adapt these files to the project, including the Python version, package names, and the `search-path` and `known-first-party` lists. A single-package project uses the same files without the workspace tables. An existing repo keeps its own tools; add the missing pieces around them.

Every check exits non-zero on any finding, because agents read exit codes. Ruff and Pyrefly have no warning tier here; everything selected is an error.

Run `rtk uv run --no-project test/verify-ai-steering.py` after editing these templates. It checks manifest syntax, the Uvicorn dependency, and Ruff plus runtime Pydantic/FastAPI annotations. Before adoption, also exercise a fresh uv workspace, same-named tests in two members, and installed hooks from a normal shell. The example workflow has not run on GitHub, and the Docker snippet has not been built.

### Layout

```
pyproject.toml          # virtual workspace root: members, dev tools, Ruff/pytest/Pyrefly config
uv.lock                 # committed
.python-version
justfile
packages/common/        # example shared package; extract only once a second consumer needs it, and name it for its purpose
  pyproject.toml
  src/acme_common/{__init__.py,py.typed}
  tests/
apps/api/               # deployable app
  pyproject.toml
  src/acme_api/
  tests/
```

Tool config lives only in the root `pyproject.toml`. Members hold only their own metadata and dependencies.

### Root `pyproject.toml`

```toml
[project]
name = "acme"
version = "0.0.0"
description = "Workspace root (virtual; not published)"
requires-python = ">=3.13"

[tool.uv]
package = false
default-groups = ["dev"]

[tool.uv.workspace]
members = ["packages/*", "apps/*"]

[tool.uv.sources]
acme-common = { workspace = true }
acme-api = { workspace = true }

[dependency-groups]
dev = [
  "acme-common",
  "acme-api",
  "lefthook>=2",
  "pyrefly>=1.3",
  "pytest>=9",
  "pytest-asyncio>=1",
  "ruff>=0.16",
]

[tool.ruff]
line-length = 100
target-version = "py313"
src = ["packages/*/src", "apps/*/src"]

[tool.ruff.lint]
select = [
  "E", "W", "F", "I", "N", "UP", "B", "A", "C4", "DTZ", "T20", "SIM", "PTH", "PERF",
  "RUF", "ASYNC", "S", "PT", "TID", "TC", "ANN", "ARG", "LOG", "G", "PGH", "FURB",
]
ignore = ["ANN401"]

[tool.ruff.lint.flake8-tidy-imports]
ban-relative-imports = "all"

[tool.ruff.lint.flake8-type-checking]
runtime-evaluated-base-classes = ["pydantic.BaseModel", "pydantic_settings.BaseSettings"]
runtime-evaluated-decorators = ["pydantic.validate_call"]

[tool.ruff.lint.isort]
known-first-party = ["acme_common", "acme_api"]

[tool.ruff.lint.per-file-ignores]
"**/tests/**" = ["S101", "ANN", "ARG"]

[tool.pytest.ini_options]
testpaths = ["packages", "apps"]
addopts = ["-ra", "--strict-markers", "--strict-config", "--import-mode=importlib"]
asyncio_mode = "auto"

[tool.pyrefly]
preset = "strict"
python-version = "3.13"
search-path = ["packages/common/src", "apps/api/src"]
```

- `package = false` and no `[build-system]` make the root virtual: it installs nothing itself. Members come in through `dev`, so a plain `uv sync` installs every member editable plus the tooling.
- Every member listed in `[tool.uv.workspace]` and used by another member needs `{ workspace = true }` in `[tool.uv.sources]`. Add it to the root `sources` and `dev` group so the root environment includes it, and to each depending member's own `sources`.
- Ruff's `TID252` (with `ban-relative-imports = "all"`) enforces absolute imports. `TC` moves type-only imports under `TYPE_CHECKING`. `T20` bans `print`, and `S`/`ANN` catch security and missing-annotation issues.
- `[tool.ruff.lint.flake8-type-checking]` protects the listed Pydantic classes/decorators. Add other runtime-evaluated base classes (SQLModel, for example) when used. Ordinary FastAPI route decorators are not covered by this list: keep their annotation imports available at runtime, using a targeted `# noqa: TC003` (or TC001/TC002 for first-/third-party imports). Safe `ruff check --fix` reports these findings without moving the imports; applying the unsafe move can break OpenAPI generation or requests. Do not apply unsafe fixes blindly.
- `--import-mode=importlib` is required because each member has its own `tests/` directory. Under the default import mode, two members with `tests/test_models.py` fail collection with an import-file mismatch.
- Add `"D"` with `convention = "google"` only if the repo wants docstring enforcement.
- Pyrefly's `strict` preset adds `implicit-any` and `missing-override-decorator` on top of the default checks. Do not weaken it; fix the code.

#### FastAPI runtime annotation imports

```python
from __future__ import annotations

from datetime import date  # noqa: TC003 -- FastAPI resolves route annotations at runtime.

from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def read(day: date) -> str:
    return str(day)
```

Verify `app.openapi()` and a request to `/?day=2026-10-26` after formatting/linting. Pydantic model checks alone do not exercise route signatures. Uvicorn belongs in the API member's runtime dependencies because the Docker entrypoint launches it.

#### Pyrefly gotcha: `search-path` is mandatory in a workspace

`uv sync` installs members as editable packages, so Pyrefly sees their `src` directories as third-party site-packages and silently excludes them from the check. The result is `0 errors` on code that has errors. List every member's `src` in `search-path` (globs are not supported; add a line when adding a member). Confirm coverage with `uv run pyrefly dump-config`: every first-party file must appear under "Covered files".

### Member `pyproject.toml`

A library (`packages/common/pyproject.toml`):

```toml
[project]
name = "acme-common"
version = "0.0.0"
requires-python = ">=3.13"
dependencies = ["pydantic>=2.9"]

[build-system]
requires = ["uv_build>=0.11,<0.12"]
build-backend = "uv_build"
```

An app that depends on it (`apps/api/pyproject.toml`):

```toml
[project]
name = "acme-api"
version = "0.0.0"
requires-python = ">=3.13"
dependencies = ["acme-common", "fastapi>=0.115", "uvicorn>=0.30"]

[tool.uv.sources]
acme-common = { workspace = true }

[build-system]
requires = ["uv_build>=0.11,<0.12"]
build-backend = "uv_build"
```

`uv_build` expects `src/<name_with_underscores>/__init__.py`. Keep the `uv_build` range on the same minor as the uv in use (`uv --version`) and bump both together. Add an empty `py.typed` to library packages. Dev tooling stays in the root `dev` group; a member's runtime dependencies stay in that member's `dependencies`.

### `justfile` (root)

```just
default:
    @just --list

sync:
    uv sync --locked

setup: sync
    uv run lefthook install

fmt:
    uv run ruff format .
    uv run ruff check --fix .

check:
    uv run ruff format --check .
    uv run ruff check .
    uv run pyrefly check

test *args:
    uv run pytest {{args}}
```

`just setup` installs the environment and the git hooks; run it once per clone. `just check` is the single gate for formatting, lint, and types; `just test` runs pytest, and takes extra arguments (`just test -k name apps/api`).

### uv commands

```bash
uv init --bare                              # start a root pyproject.toml, then add the workspace tables
uv init --lib --vcs none --name acme-common packages/common # new library member (src layout, uv_build, py.typed)
uv init --package --vcs none --name acme-api apps/api # new application member (src layout; --app alone makes a flat layout)
uv sync                                     # install every member + dev group; updates uv.lock
uv sync --locked                            # fail if uv.lock is stale (CI, just sync)
uv lock --check                             # verify the lockfile without installing
uv add --package acme-api httpx             # add a runtime dependency to ONE member
uv add --package acme-api acme-common       # add a workspace member as a dependency
uv add --dev <tool>                         # add to the root dev group (from the root)
uv remove --package acme-api httpx
uv run pytest apps/api                      # run in the shared workspace environment
uv run --package acme-api <cmd>             # run with that member's environment
uv run python -c "import acme_common"
uv lock --upgrade-package <name>            # bump a single dependency
uv tree                                     # inspect the resolved dependency graph
```

- Dependencies belong to the member that imports them; use `uv add --package`. Only shared tooling goes in the root `dev` group.
- Commit `uv.lock`. Agents run `uv sync` locally and commit the updated lockfile; CI and Docker use `--locked`.
- Pin the interpreter in `.python-version` (`3.13`), and let `uv` provision it.
- Run scripts with `uv run`, and use `uv run --with <pkg>` or inline script metadata (`# /// script`) for one-off scripts that do not belong to the project.

### Single-package project

Drop `[tool.uv.workspace]`, `[tool.uv.sources]`, and `package = false`; add `[build-system]` with `uv_build`; put dependencies and the `dev` group in the same `pyproject.toml`; set `src = ["src"]` for Ruff and `search-path = ["src"]` for Pyrefly; set `testpaths = ["tests"]`.

### `lefthook.yml` (root)

```yaml
pre-commit:
  parallel: true
  jobs:
    - name: format
      glob: "*.py"
      run: uv run ruff format --force-exclude {staged_files}
      stage_fixed: true
    - name: lint
      glob: "*.py"
      run: uv run ruff check --force-exclude {staged_files}
    - name: typecheck
      glob: "*.py"
      run: uv run pyrefly check
```

Pyrefly runs project-wide on each commit; it is fast enough that checking only staged files is unnecessary. `--force-exclude` keeps Ruff's `exclude` (generated protobuf, migrations) in force for explicitly passed files. `lefthook` comes from the root `dev` group; `just setup` installs the hooks. See `github-actions.md` for the shared `commit-msg` and branch guard; the Python pre-push quality job runs the existing `just check` recipe. Existing repos keep their hook manager.

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
      - uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
        with:
          enable-cache: true
      - run: uv sync --locked
      - name: Format check
        run: uv run ruff format --check .
      - name: Lint
        run: uv run ruff check .
      - name: Type check
        run: uv run pyrefly check

  test:
    needs: check
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
        with:
          enable-cache: true
      - run: uv sync --locked
      - run: uv run pytest
```

Every action is pinned to a full commit SHA, per `github-actions.md`. Separate steps make a failure name its cause (format, lint, or types). `test` waits on `check` so broken code never burns test minutes.

### Docker

```dockerfile
FROM python:3.13-slim
COPY --from=ghcr.io/astral-sh/uv:0.11 /uv /uvx /bin/
WORKDIR /app
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=apps/api/pyproject.toml,target=apps/api/pyproject.toml \
    --mount=type=bind,source=packages/common/pyproject.toml,target=packages/common/pyproject.toml \
    uv sync --locked --no-install-workspace --package acme-api --no-dev

COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --package acme-api --no-dev

RUN useradd --system --no-create-home app
USER app
ENV PATH="/app/.venv/bin:$PATH"
CMD ["uvicorn", "acme_api.main:app", "--host", "0.0.0.0"]
```

- Dependency layers cache separately from source. Add each member's `pyproject.toml` bind mount as members grow.
- Pin the uv image to the project's uv minor (or a digest), never `latest`.
- `COPY . /app` needs a `.dockerignore` listing at least `.venv`, `.git`, `__pycache__`, and `.*_cache`. Otherwise the host `.venv` lands in the image.
- The workspace installs as editable, so the venv points at the workspace members' source directories under `/app`; that works in this single-stage build. In a multi-stage build, add `--no-editable` to the final `uv sync` and copy only `.venv`.
- `--host 0.0.0.0` is correct inside a container; the platform decides what is exposed.

### Applying to a repo

Run in this order; each step is verifiable before the next:

1. Write the root `pyproject.toml` and member `pyproject.toml` files, `.python-version`, and `.gitignore` entries for `.venv`, `__pycache__`, `.pytest_cache`, and `.ruff_cache`. Run `uv sync` and confirm `uv lock --check` passes.
2. Run `uv run ruff format .`, then `uv run ruff check --fix .`, then fix what remains. A first Ruff run on an existing codebase surfaces many `ANN`, `S`, and `TC` findings; fix them by rule, not by widening `ignore`.
3. Set `search-path`, run `uv run pyrefly dump-config`, and confirm every first-party file is covered. Then run `uv run pyrefly check` and fix every error. Adopt strictness on an existing repo in stages: start with `preset = "default"`, fix, then switch to `"strict"`.
4. Run `uv run pytest`.
5. Write the `justfile` and confirm `just check` and `just test` pass.
6. Write `lefthook.yml`, run `just setup`, and make a deliberately broken commit to confirm the hook blocks it.
7. Write the CI workflow and confirm both jobs pass on a branch.

In a repo that also has TypeScript, do not apply this file and `typescript.md` side by side. Use `polyglot-monorepo.md`, which merges the root manifests, hooks, and CI.
