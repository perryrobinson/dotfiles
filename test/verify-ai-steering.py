# /// script
# requires-python = ">=3.13"
# dependencies = ["fastapi>=0.115", "httpx>=0.28", "ruff>=0.16", "uvicorn>=0.30"]
# ///
"""Focused template regression checks: rtk uv run --no-project test/verify-ai-steering.py."""

import importlib.util
import json
import re
import runpy
import subprocess
import tempfile
from pathlib import Path

import tomllib
from fastapi.testclient import TestClient

ROOT = Path(__file__).resolve().parents[1] / "config/ai/steering"


def blocks(text: str, language: str) -> list[str]:
    return re.findall(rf"```{language}\n(.*?)```", text, re.DOTALL)


def main() -> None:
    docs = {path.name: path.read_text() for path in ROOT.glob("*.md")}
    for text in docs.values():
        for block in blocks(text, "json"):
            json.loads(block)
        for block in blocks(text, "toml"):
            tomllib.loads(block)

    ts = docs["typescript.md"]
    default, optional = ts.split("### Optional: Turborepo")
    scripts = json.loads(blocks(default, "json")[0])["scripts"]
    assert scripts["build"] == "pnpm -r run build"
    checks = scripts["check"].split(" && ")
    assert checks.index("pnpm run build") < checks.index("pnpm run typecheck")
    assert checks.index("pnpm run build") < checks.index("pnpm run lint")
    assert "turbo run" not in default
    turbo = json.loads(blocks(optional, "json")[0])
    assert {"tsconfig.base.json", ".oxlintrc.json"} <= set(turbo["globalDependencies"])
    for task in turbo["tasks"].values():
        if "inputs" in task:
            assert "$TURBO_DEFAULT$" in task["inputs"]

    poly = docs["polyglot-monorepo.md"]
    workflow = blocks(poly, "yaml")[-1]
    assert "  ts:" in workflow and "  py:" in workflow
    assert "needs: [ts, py]" in workflow
    assert 'test "$RESULTS" = "success success"' in workflow
    assert "needs.detect" not in workflow and "  detect:" not in workflow
    for text in docs.values():
        assert "run: just check-affected" not in text

    python = docs["python.md"]
    manifests = [tomllib.loads(block) for block in blocks(python, "toml")]
    api = next(
        config
        for config in manifests
        if config.get("project", {}).get("name") == "acme-api"
    )
    assert any(dep.startswith("uvicorn") for dep in api["project"]["dependencies"])
    assert importlib.util.find_spec("uvicorn") is not None

    with tempfile.TemporaryDirectory(prefix="steering-check-") as directory:
        scratch = Path(directory)
        config = scratch / "pyproject.toml"
        config.write_text(blocks(python, "toml")[0])
        route = scratch / "routes.py"
        route.write_text(blocks(python, "python")[0])
        model = scratch / "models.py"
        model.write_text(
            "from __future__ import annotations\n\nfrom datetime import date\n\n"
            "from pydantic import BaseModel\n\n\nclass Payload(BaseModel):\n    day: date\n"
        )
        subprocess.run(
            ["rtk", "ruff", "check", "--config", str(config), str(route), str(model)],
            check=True,
        )
        subprocess.run(
            [
                "rtk",
                "ruff",
                "format",
                "--check",
                "--config",
                str(config),
                str(route),
                str(model),
            ],
            check=True,
        )
        namespace = runpy.run_path(str(route))
        app = namespace["app"]
        app.openapi()
        with TestClient(app) as client:
            response = client.get("/", params={"day": "2026-10-26"})
            assert response.status_code == 200, response.text
            assert response.json() == "2026-10-26"
        payload = runpy.run_path(str(model))["Payload"].model_validate(
            {"day": "2026-10-26"}
        )
        assert payload.day.isoformat() == "2026-10-26"

    print(
        "Steering checks passed: manifests, ordering, cache defaults, CI coverage, runtime annotations."
    )


if __name__ == "__main__":
    main()
