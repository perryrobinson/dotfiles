---
title: Testing and Verification Steering
description: Opinionated defaults for choosing and reporting verification commands.
applies_when:
  - Running tests
  - Running lint, format, or typecheck
  - Verifying codegen freshness
  - Reporting verification status
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
- For generated code, run the codegen command and check for drift.
- If full verification is expensive or blocked, run the closest focused check and clearly state what did and did not run.
- Do not claim work is complete without fresh verification evidence from this machine.
