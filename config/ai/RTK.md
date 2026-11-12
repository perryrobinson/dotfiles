# RTK - Rust Token Killer (Codex CLI)

**Usage**: Token-optimized CLI proxy for shell commands.

## Non-Negotiable Rule

Always prefix shell commands with `rtk`. This applies to reads, searches, git, package managers, test runners, and build tools.

Use the most specific RTK wrapper available. Do not satisfy the prefix rule with
`rtk proxy` or `rtk run` when a filtered wrapper exists.

For Python, prefer `rtk pytest ...`, `rtk ruff ...`, `rtk mypy ...`, or
`rtk pip ...` for those tools, and use `rtk uv run ...` for general Python
execution. Do not call raw `python`, `python3`, `pytest`, or `pip` unless RTK
cannot perform the task and the fallback is explicitly explained first.

## High-Value Rewrites

```bash
rtk read pyproject.toml                 # not cat/head/tail for simple reads
rtk grep -n "pattern" path              # not raw grep
rtk find . -name "*.ts"                 # not raw find
rtk ls -la                              # not raw ls
rtk wc -l file                          # not raw wc
rtk git add path                        # not raw git
rtk gh pr view                          # not raw gh
rtk docker compose ps                   # not raw docker compose
rtk pnpm install                        # not raw pnpm
rtk npx nx run app:test                 # not raw npx
rtk playwright test                     # not npx playwright
rtk curl -s https://example.com/data    # not raw curl
rtk uv sync                             # not raw uv
rtk pytest tests/unit/test_api.py -q    # not python -m pytest
```

## Examples

```bash
rtk git status
rtk git diff
rtk gh pr view
rtk pnpm exec nx run app:test
rtk go test ./...
rtk mvn test
rtk pytest apps/py-bff-api/tests/test_routes.py -v
rtk uv run pytest apps/py-bff-api/tests/test_routes.py -v
rtk uv run python -c "print(42)"
```

## Fallback Rule

If `rtk` rejects a command form, retry with the closest compliant `rtk` form before using a raw command. If a raw command is required, say why before running it.

When unsure, ask RTK for the canonical wrapper:

```bash
rtk rewrite 'cat pyproject.toml'
rtk rewrite 'npx playwright test'
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
rtk gain
rtk discover
rtk rewrite 'cat pyproject.toml'
```
