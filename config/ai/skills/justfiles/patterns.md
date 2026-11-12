# Justfile patterns

Worked cases for recipes that break quietly: they parse, pass `just --fmt --check`, and run fine on the easy input, then do the wrong thing on a path with a space, an unexpected environment or a second caller. The paired cases give the bad version with what it does on just 1.59, and the good version. Test the good version with the input that broke the bad one. The final two cases show complete workspace entry points.

## Passing several paths through

A recipe takes any number of paths and hands them to a tool.

Bad: `{{ paths }}` pastes the arguments back joined by spaces, so `just probe "My Files/a.txt" b.txt` gives the tool three arguments: `My`, `Files/a.txt` and `b.txt`.

```just
probe *paths:
    tool inspect {{ paths }}
```

Good: `[positional-arguments]` passes each argument through as given, and `"$@"` keeps them apart.

```just
[positional-arguments]
probe *paths:
    tool inspect "$@"
```

## Running a command through another shell

`ssh host cmd` and `docker exec box sh -c cmd` hand a command string to a second shell, on the other side, which parses it again.

Bad: the path is wrapped in single quotes inside double quotes. A path containing `'` ends the quoting early and the remote shell fails ("Unterminated quoted string"). A `$` or `"` is expanded by the local shell before the command even leaves.

```just
remote-probe path:
    ssh host "/opt/tools/probe '{{ path }}'"
```

Good: quote once for each shell. The inner `quote()` makes the path safe for the remote shell, and the outer one gets that whole string past the local shell as one argument.

```just
remote-probe path:
    ssh host /opt/tools/probe {{ quote(quote(path)) }}
```

## A flag that's passed only sometimes

An optional parameter adds a flag such as `--target <target>` to several commands.

Bad: the same `if` expression is pasted into every line. It works, but each copy has to be edited together, and the next line someone adds tends to leave it out.

```just
run target="":
    tool {{ if target == "" { "" } else { "--target " + quote(target) } }} build
    tool {{ if target == "" { "" } else { "--target " + quote(target) } }} verify
```

Good: build the command once as a bash array, so every line that uses it gets the flag.

```just
[positional-arguments]
[script('bash')]
run target="":
    set -euo pipefail
    tool=(tool)
    if [ -n "$1" ]; then tool+=(--target "$1"); fi
    "${tool[@]}" build
    "${tool[@]}" verify
```

When the tool reads the choice from an environment variable, passing it once with `env` is simpler still.

## A toolchain's environment on every recipe

Several recipes need the same environment, such as an SDK path.

Bad: each recipe spells out `env SDK_HOME=... SDK_LIB=...`. A recipe added later without it picks up whatever the caller's shell has, and works on one machine only.

```just
sdk_home := env("SDK_HOME", "/opt/sdk")
sdk_lib := sdk_home / "lib"

build:
    env SDK_HOME={{ sdk_home }} SDK_LIB={{ sdk_lib }} tool build

test:
    env SDK_HOME={{ sdk_home }} SDK_LIB={{ sdk_lib }} tool test
```

Good: `export` the variables once, and every recipe line gets them. The caller's `SDK_HOME` wins through `env()`; `SDK_LIB` is derived from it. Use `env("SDK_LIB", SDK_HOME / "lib")` instead if that path also needs its own override.

```just
export SDK_HOME := env("SDK_HOME", "/opt/sdk")
export SDK_LIB := SDK_HOME / "lib"

build:
    tool build

test:
    tool test
```

## A step that runs after another

`setup` installs dependencies, then stages files that need them.

Bad: calling `just` from inside a recipe starts a separate `just` run. Command-line overrides are lost (`just mode=release setup` stages with the default `mode`), and the nested run reads the justfile again from scratch.

```just
mode := "debug"

setup:
    pnpm install
    just stage

stage:
    pnpm run stage --mode {{ mode }}
```

Good: a dependency after `&&` runs after the recipe's own lines, in the same `just` run, with the same overrides.

```just
mode := "debug"

setup: && stage
    pnpm install

stage:
    pnpm run stage --mode {{ mode }}
```

## Working in a subdirectory

A tool has to run inside `apps/web`.

Bad: every line repeats `cd apps/web &&`, and a line that forgets it runs in the root without any error.

```just
web-build:
    cd apps/web && pnpm install
    cd apps/web && pnpm build
```

Good: `[working-directory]` covers every line. Paths on those lines are now relative to `apps/web`, so a file in the repo root becomes `../../file`, or `{{ justfile_directory() }}/file`.

```just
[working-directory('apps/web')]
web-build:
    pnpm install
    pnpm build
```

## A recipe for one OS

A native package build needs macOS and Xcode.

Bad: on Linux the recipe is listed and runs, then fails partway with an unrelated error such as `xcodebuild: command not found`.

```just
native-build:
    xcodebuild -scheme Package build
```

Good: the real recipe exists only on macOS, and a same-named recipe on the other systems explains why it can't run. `just --list` shows one `native-build` on every system.

```just
# Build the native package (macOS with Xcode).
[macos]
native-build:
    xcodebuild -scheme Package build

[doc('Build the native package (macOS with Xcode).')]
[linux]
[windows]
native-build:
    @echo "native-build needs macOS with Xcode" >&2
    @exit 1
```

## A Python workspace front door

Use the root environment for workspace checks. `setup` syncs locked dependencies before installing hooks; `sync` remains useful for CI or refreshing the environment without hook setup. The examples assume the repo already chose uv, Ruff, Pyrefly, pytest and Lefthook; keep an existing repo’s tools.

```just
# List available workflows.
default:
    @just --list

# Sync the locked workspace environment.
sync:
    uv sync --locked

# Install the workspace environment and git hooks after cloning.
setup: sync
    uv run lefthook install

# Format Python and apply safe lint fixes.
fmt:
    uv run ruff format .
    uv run ruff check --fix .

# Check formatting, lint and types across the workspace.
check:
    uv run ruff format --check .
    uv run ruff check .
    uv run pyrefly check

# Run pytest with arguments preserved, including paths with spaces.
[positional-arguments]
test *args:
    uv run pytest "$@"
```

`just test -k "name and not other" "tests/some file.py"` gives pytest three arguments after its name, preserving the expression and path. A failing formatter, linter or typechecker stops `check` and fails the hook or CI caller. `just setup` is for a developer clone; CI installs locked dependencies without installing hooks.

## Adding a second toolchain

For a pnpm + uv workspace, keep one root entry point with per-language gates for split CI jobs. The pnpm root `prepare` script already installs Lefthook, so `setup` needs no separate hook-install step. Package scripts own TypeScript dependency build ordering; `just` calls those scripts instead of reconstructing their graph.

```just
# List available workflows.
default:
    @just --list

# Install both toolchains’ dependencies and the pnpm-managed hooks.
setup:
    pnpm install
    uv sync --locked

# Format both languages and apply safe Python lint fixes.
fmt:
    pnpm run format
    uv run ruff format .
    uv run ruff check --fix .

# Check both languages.
check: check-ts check-py

# Build TypeScript dependencies and run its quality gate.
[group('ts')]
check-ts:
    pnpm run check

# Check Python formatting, lint and types.
[group('py')]
check-py:
    uv run ruff format --check .
    uv run ruff check .
    uv run pyrefly check

# Test both languages.
test: test-ts test-py

# Build dependencies and test TypeScript.
[group('ts')]
test-ts:
    pnpm run test

# Test Python with arguments preserved.
[group('py')]
[positional-arguments]
test-py *args:
    uv run pytest "$@"
```

The TypeScript CI job runs `just check-ts` and `just test-ts`; the Python job runs `just check-py` and `just test-py`. Neither runs the cross-language `setup`, `check` or `test` recipe. Both jobs install the pinned `just` version and their own locked dependencies first. A hook that checks the whole repo calls `just check`.
