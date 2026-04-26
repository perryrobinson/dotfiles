---
title: Go Steering
description: Opinionated defaults for Go modules, workspaces, service structure, tests, vetting, and protobuf tooling.
applies_when:
  - Go project setup
  - Go project changes
  - Go service development
  - Go tests or vetting
  - Go protobuf generation
tags:
  - go
  - go-work
  - go-modules
  - protobuf
  - buf
---

# Go Steering

- Use the repo's Go workspace or module files as the source of truth.
- Prefer standard library packages until a dependency clearly pays for itself.
- Keep Go services boring and explicit: small packages, clear interfaces at boundaries, context-aware APIs, and errors returned rather than hidden.
- Use `cmd/<service>` for executable entry points and keep domain/application logic outside `main`.
- Prefer structured logging with `log/slog` unless the repo has already standardized on another logger.
- Use environment-based configuration with typed config structs. Avoid global mutable config.
- Always run `gofmt` or `go fmt ./...` after editing Go files.
- Prefer `go test ./...` and `go vet ./...` for broad checks when the repo does not provide narrower commands.
- Add table-driven tests for branching business logic and boundary behavior.
- Use `errors.Is`, `errors.As`, and error wrapping with `%w` for inspectable errors.
- Keep concurrency simple. Use `context.Context`, bounded goroutines, and clear cancellation paths.
- Manage dependencies with `go mod tidy` after changing imports or module metadata.
- Use Buf for Protocol Buffers linting, formatting, and generation when present.
- Do not edit generated Go protobuf outputs by hand. Regenerate them through the repo's codegen target.
