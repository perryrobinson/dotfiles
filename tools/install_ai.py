#!/usr/bin/env python3
"""Manually install repository AI guidance and skills; no third-party dependencies."""

import argparse
import hashlib
import json
import os
import shutil
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def atomic_write(path, data, mode=0o600):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
        os.chmod(name, mode)
        os.replace(name, path)
    finally:
        Path(name).unlink(missing_ok=True)


def payload(home):
    source = ROOT / "config/ai"
    codex = Path(os.environ.get("CODEX_HOME") or home / ".codex")
    claude = Path(os.environ.get("CLAUDE_CONFIG_DIR") or home / ".claude")
    opencode = Path(os.environ.get("XDG_CONFIG_HOME") or home / ".config") / "opencode"
    if not all(path.is_absolute() for path in (codex, claude, opencode)):
        raise ValueError("Config directory overrides must be absolute paths.")
    guidance = (
        (source / "AGENTS.md")
        .read_text()
        .replace("~/dotfiles/config/ai/", str(source) + "/")
    )
    # Expand the import for tools that do not implement Claude's @file syntax.
    guidance = guidance.replace("@RTK.md", (source / "RTK.md").read_text())
    files = {
        codex / "AGENTS.md": guidance.encode(),
        claude / "CLAUDE.md": guidance.encode(),
        opencode / "AGENTS.md": guidance.encode(),
        home / ".kiro/steering/dotfiles.md": guidance.encode(),
    }
    files = {path: (data, 0o644) for path, data in files.items()}
    for skill in sorted((source / "skills").iterdir()):
        if not skill.is_dir() or not (skill / "SKILL.md").is_file():
            raise ValueError(f"Invalid skill directory: {skill}")
        for path in sorted(skill.rglob("*")):
            if path.is_symlink():
                raise ValueError(f"Skill symlinks are not supported: {path}")
            if path.is_file():
                for directory in (home / ".agents", claude, home / ".kiro"):
                    files[
                        directory / "skills" / path.relative_to(source / "skills")
                    ] = (
                        path.read_bytes(),
                        path.stat().st_mode & 0o777,
                    )
    return files


def install(home, dry_run=False, bootstrap=False):
    state_dir = home / ".local/state/dotfiles-ai"
    state_file = state_dir / "manifest.json"
    if any(p.is_symlink() for p in (state_file, *state_file.parents)):
        raise ValueError("Installer state must not use symlinks.")
    state = json.loads(state_file.read_text()) if state_file.exists() else {}
    if bootstrap and state.get("bootstrap_done"):
        raise ValueError("The one-time bootstrap has already been used.")
    managed = state.setdefault("files", {})
    conflicts = 0
    backup = None
    for path, (data, mode) in payload(home).items():
        # Never follow a destination symlink, including one in a parent directory.
        if any(parent.is_symlink() for parent in path.parents):
            print(f"CONFLICT (symlink parent) {path}")
            conflicts += 1
            continue
        exists = path.exists() or path.is_symlink()
        current = (
            path.read_bytes() if path.is_file() and not path.is_symlink() else None
        )
        key = str(path)
        if current == data:
            if bootstrap and not dry_run:
                managed[key] = digest(data)
            if managed.get(key) == digest(data):
                print(f"UNCHANGED {path}")
            else:
                print(f"IDENTICAL (unmanaged) {path}")
            continue
        conflict = exists and (current is None or managed.get(key) != digest(current))
        if conflict and not bootstrap:
            print(f"CONFLICT (preserved) {path}")
            conflicts += 1
            continue
        print(f"{'BACKUP + ' if conflict else ''}INSTALL {path}")
        if dry_run:
            continue
        if conflict:
            state_dir.mkdir(parents=True, exist_ok=True)
            if backup is None:
                backup = Path(tempfile.mkdtemp(prefix="backup-", dir=state_dir))
                print(f"Backups: {backup}")
            saved = backup / path.relative_to(path.anchor)
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(path), saved)
        atomic_write(path, data, mode)
        managed[key] = digest(data)
        # Persist each successful write so an interrupted run can resume safely.
        atomic_write(state_file, json.dumps(state, indent=2).encode() + b"\n")
    if not dry_run:
        if bootstrap:
            state["bootstrap_done"] = True
        atomic_write(state_file, json.dumps(state, indent=2).encode() + b"\n")
    return 1 if conflicts else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run", action="store_true", help="preview without writing"
    )
    parser.add_argument(
        "--bootstrap",
        action="store_true",
        help="one time only: back up and replace conflicting destination files",
    )
    args = parser.parse_args()
    try:
        return install(Path.home(), args.dry_run, args.bootstrap)
    except (OSError, ValueError) as error:
        parser.exit(2, f"Installation failed: {error}\n")


if __name__ == "__main__":
    raise SystemExit(main())
