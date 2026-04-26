---
title: Git Steering
description: Opinionated defaults for branches, commits, staging, and PR-oriented work.
applies_when:
  - Git commits
  - Branch or PR work
  - Staging files
  - Publishing changes
tags:
  - git
  - conventional-commits
  - branches
  - pull-requests
---

# Git Steering

- Commit frequently at discrete logical milestones when working on a branch.
- Use Conventional Commits for all commit messages.
- Prefer small, reviewable commits over broad mixed-purpose commits.
- Do not stage unrelated user changes.
- Do not push directly to `main`; use a feature branch and PR.
- Before committing, review the staged diff and run the narrowest relevant verification.

Examples:

- `feat: add dashboard filters`
- `fix(api): handle missing stats rows`
- `docs: update local setup notes`
- `test: cover generated client errors`
