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
- For TypeScript changes, include formatting/linting, typechecking, and relevant tests.
- For Python changes, include Ruff format/check, `ty` when present, and relevant pytest targets.
- For Go changes, include `go fmt`, `go vet`, and relevant `go test` targets.
- For Java changes, include the repo's compile/check target and relevant JUnit tests.
- For generated code, run the codegen command and check for drift.
- When fixing a bug, prefer adding or updating a regression test that fails before the fix and passes after it when practical.
- Verify the actual user-facing path when the change affects UI, API behavior, CLI behavior, Docker startup, or generated artifacts.
- If full verification is expensive or blocked, run the closest focused check and clearly state what did and did not run.
- Report verification with command names and outcomes, not vague statements.
- Do not claim work is complete without fresh verification evidence from this machine.
