---
title: Testing and Verification Steering
description: Opinionated defaults for choosing, sequencing, and reporting verification commands.
applies_when:
  - Running tests
  - Running lint, format, or typecheck
  - Verifying codegen freshness
  - Reporting verification status
  - Choosing focused versus broad checks
tags:
  - testing
  - verification
  - linting
  - typechecking
  - codegen
---

# Testing and Verification Steering

- Run the narrowest relevant formatter, typecheck, lint, and tests after code changes.
- Prefer repo-provided commands such as `just check`, `just test`, Nx targets, package filters, or affected checks.
- Use focused checks first while iterating, then run broader repo-level or affected checks before committing or claiming completion.
- For TypeScript changes, use the repo's check scripts and relevant tests. The new-project default is `pnpm run check` (dependency builds, TypeScript, oxlint, formatting), then `pnpm run test`. Scope package work with `pnpm --filter <package> run <task>` after building needed dependencies; use Turbo/Nx filters only when the repo already provides them.
- For Python changes, use Ruff format/check, the repo's typechecker, and relevant pytest targets (`just check` and `just test` when provided). Pyrefly is the new-project default; keep mypy, pyright, or ty in existing repos.
- For Go changes, include `go fmt`, `go vet`, and relevant `go test` targets.
- For Java changes, include the repo's compile/check target and relevant JUnit tests.
- For generated code, run the codegen command and check for drift.
- For CI workflows, lint them with `actionlint` and run any non-trivial shell logic locally against real commits. For git hooks and task-runner filters, exercise them in a scratch repo with a deliberately broken change; a config that parses is not evidence that it blocks or selects what it should.
- When fixing a bug, prefer adding or updating a regression test that fails before the fix and passes after it when practical.
- Verify the actual user-facing path when the change affects UI, API behavior, CLI behavior, Docker startup, or generated artifacts.
- If full verification is expensive or blocked, run the closest focused check and clearly state what did and did not run.
- Report verification with command names and outcomes, not vague statements.
- Do not claim work is complete without fresh verification evidence from this machine.

- When editing the reusable AI templates, run `rtk uv run --no-project test/verify-ai-steering.py`, then exercise changed command paths in a fresh scratch repo. Include clean and failing checks, dependency build ordering, installed pre-push hooks, and runtime FastAPI annotations. Cached/affected workflows also need invalidation and fixture/shared-config cases.
