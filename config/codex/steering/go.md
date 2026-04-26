---
title: Go Steering
description: Opinionated defaults for Go modules, workspaces, tests, vetting, and protobuf tooling.
applies_when:
  - Go project changes
  - Go tests or vetting
  - Go protobuf generation
tags:
  - go
  - protobuf
  - buf
---

# Go Steering

- Use the repo's Go workspace or module files as the source of truth.
- Prefer `go test ./...` and `go vet ./...` for broad checks when the repo does not provide narrower commands.
- Use Buf for Protocol Buffers linting, formatting, and generation when present.
- Do not edit generated Go protobuf outputs by hand. Regenerate them through the repo's codegen target.
