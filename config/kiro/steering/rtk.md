---
title: RTK - Rust Token Killer
description: Token-optimized shell command proxy. Always use rtk prefix for shell commands.
applies_when:
  - Any shell command execution
  - Running tests, builds, git operations, or CLI tools
tags:
  - rtk
  - shell
  - tools
---

# RTK - Rust Token Killer

Always prefix shell commands with `rtk` for token-optimized output.

```bash
rtk git status
rtk git log
rtk cargo test
rtk npm run build
rtk pytest -q
rtk docker ps
```

## Meta Commands

```bash
rtk gain            # Token savings analytics
rtk gain --history  # Recent command savings history
rtk proxy <cmd>     # Run raw command without filtering
```

## Verification

```bash
rtk --version
which rtk
```
