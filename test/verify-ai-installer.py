"""Run with: rtk uv run --no-project test/verify-ai-installer.py."""

import importlib.util
import json
import os
import shutil
import tempfile
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("installer", ROOT / "tools/install_ai.py")
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


def main():
    with (
        tempfile.TemporaryDirectory() as temporary,
        patch.dict(os.environ, {}, clear=True),
    ):
        scratch = Path(temporary)
        home = scratch / "home"
        repo = scratch / "repo"
        shutil_source = ROOT / "config/ai"
        shutil.copytree(shutil_source, repo / "config/ai")
        installer.ROOT = repo
        custom = home / ".claude/settings.json"
        custom.parent.mkdir(parents=True)
        custom.write_text('{"custom": true}')
        guidance = home / ".claude/CLAUDE.md"
        guidance.write_text("personal guidance")
        assert installer.install(home, dry_run=True) == 1
        assert not (home / ".local").exists()
        assert installer.install(home) == 1
        assert guidance.read_text() == "personal guidance"
        assert installer.install(home, bootstrap=True) == 0
        backup = home / ".local/state/dotfiles-ai"
        assert (
            next(backup.glob("backup-*/**/CLAUDE.md")).read_text()
            == "personal guidance"
        )
        before = {p: p.read_bytes() for p in home.rglob("*") if p.is_file()}
        assert installer.install(home) == 0
        assert all(p.read_bytes() == data for p, data in before.items())
        try:
            installer.install(home, bootstrap=True)
        except ValueError:
            pass
        else:
            raise AssertionError("bootstrap must be one time")
        source = repo / "config/ai/skills/justfiles/patterns.md"
        source.write_text("updated")
        assert installer.install(home) == 0
        for directory in (".agents", ".claude", ".kiro"):
            assert (
                home / directory / "skills/justfiles/patterns.md"
            ).read_text() == "updated"
        local = home / ".agents/skills/justfiles/patterns.md"
        local.write_text("local edit")
        assert installer.install(home) == 1
        assert local.read_text() == "local edit"
        assert json.loads(custom.read_text()) == {"custom": True}
        outside = scratch / "outside"
        outside.write_text("keep")
        local.unlink()
        local.symlink_to(outside)
        assert installer.install(home) == 1
        assert outside.read_text() == "keep"
        assert str(repo / "config/ai/steering") in guidance.read_text()
        assert "@RTK.md" not in guidance.read_text()
        print("Installer checks passed.")


if __name__ == "__main__":
    main()
