---
name: justfiles
description: Writing, organizing and running `just` recipes (just 1.59+). Use when discovering repo commands through a justfile, or adding, changing, reviewing or reorganizing recipes.
---

# Justfiles

A justfile is the repo's **front door**: `just --list` answers "how do I do X here?", and the recipes are the single definition of each command that people, git hooks and CI all run. Examples are tested on just 1.59.0; check the repo’s pinned version before using newer features. `[script]` and `just --fmt` work there without `--unstable`.

Learn the house style from the existing justfile's naming and grouping, and match it. Take correctness from this skill, not from the existing file: it may already contain the bad versions shown below.

## Changing a justfile

1. **Look first.** `just --list` for what exists, `just --show <recipe>` for a recipe's source, `just --evaluate` for variable values. Extend an existing recipe or group before adding a new one.
2. **Make the change** using the execution model, the bad/good pairs and the syntax below. When a recipe takes paths or other user input, runs a command through another shell (`ssh`, `docker exec`), passes a flag only sometimes, sets up a toolchain's environment, must run after another recipe, works in a subdirectory, exists on one OS only, or combines workspace toolchains, read [patterns.md](patterns.md) first: those are where recipes break quietly.
3. **Done when** all of these hold:
   - `just --fmt --check` exits 0 (`just --fmt` rewrites the file in canonical form).
   - Every new or changed public recipe shows in `just --list` with its full doc comment.
   - `just -n <recipe> <args>` prints the commands you expect, with arguments substituted, including an argument with a space in it.
   - The recipe runs, and a failing step makes `just` exit non-zero.

## Execution model

These rules decide whether a recipe does what it reads as doing:

- **Working directory**: every recipe runs in the justfile's directory, wherever `just` was invoked from, so paths are relative to the justfile. `[working-directory('dir')]` runs a recipe in a subdirectory; `[no-cd]` runs it where the user invoked `just`.
- **One shell per line**: each line of a normal recipe runs in a fresh shell, so a `cd`, a variable or an `export` lasts only for its own line. Chain dependent commands on one line (`cd handbook && pnpm build`), or make the recipe a script.
- **Scripts**: `[script('bash')]` (or a `#!/usr/bin/env bash` first line) runs the whole body as one script, so state carries between lines. Neither stops on a failing line by default, so start the body with `set -euo pipefail`. Bare `[script]` uses `sh -eu` and does stop.
- **Failure**: a failing line stops a normal recipe and `just` exits with its code. Prefix a line with `-` to carry on past failure, `@` to run it without echoing it.
- **Interpolation before the shell**: `{{ expr }}` is pasted into the text first, then the shell parses it, so a value with a space becomes two words. Wrap values in `{{ quote(x) }}` to keep them one argument, or set `[positional-arguments]` and use `"$1"` / `"$@"`. `{{{{` writes a literal `{{`.
- **Dependencies** run before the recipe, once per argument set per `just` invocation even when listed twice. `[parallel]` runs a recipe's dependencies concurrently.

## Bad and good

Each bad version parses, passes `just --fmt --check` and looks fine in review. The note above it says what it does on just 1.59.

**`cd` on a line of its own.** Bad: the `cd` ends with its line, so `pnpm build` runs in the repo root.

```just
build:
    cd handbook
    pnpm build
```

Good: one line, or `[working-directory('handbook')]` when every line runs there.

```just
build:
    cd handbook && pnpm build
```

**A script without strict mode.** Bad: when lint fails, tests run anyway, and successful tests make `just` exit 0.

```just
[script('bash')]
check:
    tool lint
    tool test
```

Good: the first failure stops the script and fails the recipe with its exit code.

```just
[script('bash')]
check:
    set -euo pipefail
    tool lint
    tool test
```

**An unquoted argument.** Bad: `just write-report "reports/monthly summary.csv"` exits 0, writes the report to `reports/monthly`, and passes `summary.csv` to printf as an extra argument.

```just
write-report file:
    printf row > {{ file }}
```

Good: `quote()` keeps the path one word.

```just
write-report file:
    printf row > {{ quote(file) }}
```

**A doc comment over several lines.** Bad: `just --list` shows only the comment line directly above the recipe, here "for the documentation server."

```just
# Generate reference pages in generated/,
# for the documentation server.
docs-build:
    pnpm run docs:build
```

Good: one line that stands on its own. Longer notes go in the docs, or in a comment separated from the recipe by a blank line.

```just
# Generate reference pages in generated/ for the documentation server.
docs-build:
    pnpm run docs:build
```

**Comment banners as groups.** Bad: `just --list` ignores the banner as a group and shows it as the recipe's description: `assets-build # ---- Assets ----`.

```just
# ---- Assets ----
assets-build:
    tool assets
```

Good: `[group]` is what `just --list` groups by, and the doc comment sits above the attributes.

```just
# Generate the shared assets.
[group('assets')]
assets-build:
    tool assets
```

**A recipe that only renames a command.** Usually unnecessary: one more name to learn, with nothing hidden or combined. A stable entry point used by hooks or CI is a reason to keep a one-command recipe.

```just
lint:
    ruff check .
```

Good: the recipe earns its name by doing the steps that belong together.

```just
# Format and lint Python, fixing what can be fixed.
fmt:
    ruff format .
    ruff check --fix .
```

## Syntax

```just
set dotenv-load # read .env into the environment

version := "1.2.3" # variable; `just --evaluate` prints it
home := env("HOME") # required env var: missing is an error
port := env("PORT", "8080") # env var with a default
out := justfile_directory() / "out" # `/` joins paths

# List available workflows.
default:
    @just --list

# Build the release binary.
[group('build')]
build: prepare
    cargo build --release

# Serve on a port (default 8080).
[group('dev')]
serve port=port:
    python -m http.server {{ quote(port) }}

# Run tests, passing any extra arguments through.
[group('test')]
[positional-arguments]
test *args:
    cargo test "$@"

# Tag and push the current version.
[confirm('Push the release tag?')]
[group('release')]
[script('bash')]
release:
    set -euo pipefail
    tag="v{{ version }}"
    git tag "$tag"
    git push origin "$tag"

[private]
prepare:
    mkdir -p {{ quote(out) }}
```

Parameters: `name` (required), `name='default'`, `*rest` (zero or more), `+rest` (one or more). Required ones come first. A dependency can take arguments: `ci: (test "--locked")`. A dependency after `&&` runs after the recipe: `setup: && docs-build`.

Calling: `just <recipe> <args>`, `just <module>::<recipe>`, `just -n` (dry run), `just --usage <recipe>` (arguments and their help), `just --groups`, `just --summary`, `just --dump`.

## Attributes and settings

Attributes go on the lines above a recipe, below its doc comment. `just --fmt` sets their order and the spacing before trailing comments, so run it instead of aligning by hand.

| Attribute | Effect |
|---|---|
| `[group('name')]` | Lists the recipe under that heading in `just --list` |
| `[doc('text')]` | Doc text, in place of the comment |
| `[private]` (or a leading `_` in the name) | Hidden from `just --list`; still callable |
| `[confirm('prompt')]` | Asks before running; `just --yes` skips the prompt |
| `[script('bash')]` | Runs the body as one script (see Scripts above) |
| `[working-directory('dir')]`, `[no-cd]` | Changes where the recipe runs |
| `[positional-arguments]` | Arguments also arrive as `$1`, `$@` |
| `[arg('name', help='text')]` | Help text shown by `just --usage` |
| `[parallel]` | Runs dependencies concurrently |
| `[linux]`, `[macos]`, `[windows]`, `[unix]` | Recipe exists only on that OS; several on one recipe mean any of them |
| `[no-exit-message]` | Fails quietly, without just's error line |

Settings at the top of the file: `set dotenv-load`, `set export` (every variable becomes an environment variable), `set quiet` (no command echo anywhere), `set positional-arguments`, `set shell := ["bash", "-euo", "pipefail", "-c"]` (the shell for normal recipe lines). `export NAME := value` exports one variable.

Split a large justfile with `import 'other.just'` (recipes merge into this file) or `mod name 'path.just'` (recipes live under `just name::recipe` and run in that file's directory).

## Organizing

- **Default to the list**: the first recipe is `default: @just --list`, so bare `just` shows the front door.
- **Name the workflow**: `setup`, `dev`, `check`, `test`, `fmt`, `release`. In a repo with several areas, qualify names consistently with the area and give each area a `[group]`, so the same verb means the same thing in every area. Keep the repo's existing prefix/suffix convention.
- **One doc comment line per public recipe**, directly above it or above its attributes.
- **A recipe earns its place** when it hides flags worth forgetting, chains steps that must run together, sets up environment, or is what a hook or CI runs.
- **Short recipes**: past about ten lines, move the logic into a script file (`scripts/` or `tools/`) and have the recipe call it.
- **Destructive recipes** (deleting data, pushing, publishing) carry `[confirm]`.
- **Shared check gates have one definition**: CI and hooks call the existing recipes. A recipe can delegate to an authoritative package script or task runner; keep its task ordering and caching there. Staged-file formatting can call a tool directly because it has a different input set. Split CI jobs call the language-specific recipes rather than copying their bodies; they need only that language’s toolchain. CI installs an exact `just` version (these examples use `1.59.0`), and setup docs name the same version, because formatter output and stable features change between releases.
- **Workspace layout**: keep shared workflows in the root justfile. Add package justfiles/modules only for workflows local to a package, not copies of root checks. Use `import` to split root recipes while keeping their working directory; use `mod` for package-local execution. See the workspace cases in [patterns.md](patterns.md).
