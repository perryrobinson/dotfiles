# Go Steering

- Use the repo's Go workspace or module files as the source of truth.
- Prefer `go test ./...` and `go vet ./...` for broad checks when the repo does not provide narrower commands.
- Use Buf for Protocol Buffers linting, formatting, and generation when present.
- Do not edit generated Go protobuf outputs by hand. Regenerate them through the repo's codegen target.
