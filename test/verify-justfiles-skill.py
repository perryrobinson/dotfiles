"""Run with rtk uv run --no-project test/verify-justfiles-skill.py (just 1.59.0)."""

import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

SKILL = Path(__file__).resolve().parents[1] / "config/ai/skills/justfiles"


def run(directory, *args, env=None, status=0):
    result = subprocess.run(
        ["just", *args],
        cwd=directory,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == status, (args, result.stdout, result.stderr)
    return result.stdout


def main():
    assert run(SKILL, "--version").strip() == "just 1.59.0"
    with tempfile.TemporaryDirectory(prefix="justfiles-skill-", dir="/tmp") as temp:
        scratch = Path(temp)
        bin_dir = scratch / "bin"
        bin_dir.mkdir()
        stub = bin_dir / "stub"
        stub.write_text(
            "#!/usr/bin/env bash\nset -eu\n"
            'printf "%s\\n" "${0##*/} $*" >> "$CALLS"\n'
            'printf "<%s>\\n" "$@"\n'
            'if [[ "${FAIL_COMMAND:-}" == "${0##*/} $*" ]]; then exit 23; fi\n'
        )
        stub.chmod(0o755)
        for tool in ["pnpm", "uv", "cargo", "tool", "ssh"]:
            (bin_dir / tool).symlink_to(stub)
        env = dict(os.environ, PATH=f"{bin_dir}:{os.environ['PATH']}")
        examples = {}
        for file in ["SKILL.md", "patterns.md"]:
            snippets = re.findall(
                r"```just\n(.*?)```", (SKILL / file).read_text(), re.DOTALL
            )
            for index, source in enumerate(snippets):
                directory = scratch / f"{file}-{index}"
                directory.mkdir()
                (directory / "justfile").write_text(source)
                run(directory, "--fmt", "--check")
                run(directory, "--list")
                examples[file, index] = directory

        # Renamed examples must retain their original execution/listing behavior.
        pnpm = bin_dir / "pnpm"
        pnpm.unlink()
        pnpm.write_text("#!/bin/sh\npwd\n")
        pnpm.chmod(0o755)
        for index in [0, 1]:
            directory = examples["SKILL.md", index]
            (directory / "handbook").mkdir()
            expected = directory if index == 0 else directory / "handbook"
            assert run(directory, "build", env=env).strip() == str(expected)
        for index in [10, 11]:
            directory = examples["patterns.md", index]
            (directory / "packages/handbook").mkdir(parents=True)
            expected = str(directory / "packages/handbook")
            assert run(directory, "handbook-build", env=env).splitlines() == [
                expected,
                expected,
            ]
        pnpm.unlink()
        pnpm.symlink_to(stub)

        assert "docs-build # for the documentation server." in run(
            examples["SKILL.md", 6], "--list"
        )
        assert (
            "Generate reference pages in generated/ for the documentation server."
            in run(examples["SKILL.md", 7], "--list")
        )
        assert "[assets]" in run(examples["SKILL.md", 9], "--list")
        for index in [0, 1]:
            directory = examples["patterns.md", index]
            output = run(
                directory,
                "inspect-files",
                "Sample Files/report.csv",
                "totals.csv",
                env=dict(env, CALLS=str(directory / "calls")),
            )
            expected = (
                "<Sample>\n<Files/report.csv>"
                if index == 0
                else "<Sample Files/report.csv>"
            )
            assert output == f"<inspect>\n{expected}\n<totals.csv>\n"
        for index in [8, 9]:
            directory = examples["patterns.md", index]
            output = run(
                directory,
                "flavor=compact",
                "bootstrap",
                env=dict(env, CALLS=str(directory / "calls")),
            )
            assert output.endswith("<standard>\n" if index == 8 else "<compact>\n")
        if sys.platform.startswith("linux"):
            run(examples["patterns.md", 13], "system-info", status=1)

        # New script and path examples exercise their documented failure modes.
        for index in [2, 3]:
            directory = examples["SKILL.md", index]
            run(
                directory,
                "check",
                status=0 if index == 2 else 23,
                env=dict(env, CALLS=str(directory / "calls"), FAIL_COMMAND="tool lint"),
            )
            assert ("tool test" in (directory / "calls").read_text()) == (index == 2)
        for index in [4, 5]:
            directory = examples["SKILL.md", index]
            (directory / "reports").mkdir()
            run(directory, "write-report", "reports/monthly summary.csv")
            assert (
                directory
                / ("reports/monthly" if index == 4 else "reports/monthly summary.csv")
            ).read_text() == "row"

        directory = examples["SKILL.md", 12]
        output = run(
            directory,
            "test",
            "path with spaces",
            env=dict(env, CALLS=str(directory / "calls")),
        )
        assert output == "<test>\n<path with spaces>\n"

        directory = examples["patterns.md", 3]
        special = 'a\'b $HOME "quoted".csv'
        output = run(
            directory,
            "remote-inspect",
            special,
            env=dict(env, CALLS=str(directory / "calls")),
        )
        quoted = output.splitlines()[-1][1:-1]
        remote = subprocess.run(
            ["sh", "-c", 'printf "<%s>\\n" ' + quoted],
            capture_output=True,
            text=True,
            check=True,
        )
        assert remote.stdout == f"<{special}>\n"

        directory = examples["patterns.md", 5]
        for args in [(), ("target with spaces",)]:
            output = run(
                directory, "run", *args, env=dict(env, CALLS=str(directory / "calls"))
            )
            assert output.count("<--target>\n<target with spaces>") == (
                2 if args else 0
            )

        directory = examples["patterns.md", 7]
        tool = bin_dir / "tool"
        tool.unlink()
        tool.write_text('#!/bin/sh\nprintf "<%s><%s>\\n" "$TOOL_ROOT" "$TOOL_DATA"\n')
        tool.chmod(0o755)
        for recipe in ["build", "test"]:
            assert (
                run(directory, recipe, env=dict(env, TOOL_ROOT="/compiler files"))
                == "</compiler files></compiler files/share>\n"
            )

        # The two complete workspace examples: setup order, isolated CI gates,
        # exact pytest argv, and every quality step's failure reaching the caller.
        for index, polyglot in [(14, False), (15, True)]:
            directory = examples["patterns.md", index]
            calls = directory / "calls"
            local_env = dict(env, CALLS=str(calls))
            listing = run(directory)
            assert "check" in listing and "test" in listing
            run(directory, "setup", env=local_env)
            expected = (
                ["pnpm install", "uv sync --locked"]
                if polyglot
                else ["uv sync --locked", "uv run lefthook install"]
            )
            assert calls.read_text().splitlines() == expected
            calls.write_text("")
            run(directory, "fmt", env=local_env)
            expected = ["pnpm run format"] if polyglot else []
            expected += ["uv run ruff format .", "uv run ruff check --fix ."]
            assert calls.read_text().splitlines() == expected
            calls.write_text("")
            recipe = "test-py" if polyglot else "test"
            output = run(
                directory,
                recipe,
                "-k",
                "name and not other",
                "tests/some file.py",
                env=local_env,
            )
            assert (
                output
                == "<run>\n<pytest>\n<-k>\n<name and not other>\n<tests/some file.py>\n"
            )
            for step in [
                "uv run ruff format --check .",
                "uv run ruff check .",
                "uv run pyrefly check",
            ]:
                calls.write_text("")
                run(
                    directory,
                    "check",
                    env=dict(local_env, FAIL_COMMAND=step),
                    status=23,
                )
                assert calls.read_text().splitlines()[-1] == step
            if polyglot:
                for recipe, tool_name in [
                    ("check-ts", "pnpm"),
                    ("test-ts", "pnpm"),
                    ("check-py", "uv"),
                    ("test-py", "uv"),
                ]:
                    calls.write_text("")
                    run(directory, recipe, env=local_env)
                    assert all(
                        line.startswith(tool_name + " ")
                        for line in calls.read_text().splitlines()
                    )
    print(
        "PASS: 29 snippets parse/format; changed examples, workspace setup, argv, CI isolation and failure propagation."
    )


if __name__ == "__main__":
    main()
