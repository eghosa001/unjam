#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github/workflows/godot-ci.yml"
SELECTOR = ROOT / "tools/select_fast_ci_tests.py"

def fail(message: str) -> None:
    raise SystemExit(f"FAST_CI_POLICY_ERROR: {message}")

def load_selector():
    spec = importlib.util.spec_from_file_location("select_fast_ci_tests", SELECTOR)
    if spec is None or spec.loader is None:
        fail("cannot load selector module")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def main() -> None:
    text = WORKFLOW.read_text(encoding="utf-8")

    required = [
        "tools/select_fast_ci_tests.py --self-test",
        "steps.plan.outputs.tests",
        "steps.plan.outputs.visual_scope",
        "steps.plan.outputs.needs_godot",
        "fetch-depth: 0",
        "cancel-in-progress: true",
    ]
    for token in required:
        if token not in text:
            fail(f"fast workflow lost required selective-CI token: {token}")

    forbidden = [
        "install_monetization_plugins.sh",
        "--export-release",
        "--export-debug",
        "generate_block_campaign_pack.gd",
        "audit_block_campaign_pack.gd",
        "npm install",
        "sdkmanager",
    ]
    for token in forbidden:
        if token in text:
            fail(f"release-only work leaked into fast CI: {token}")

    if re.search(r"for\s+t\s+in\s+validate_", text):
        fail("fast CI contains a hardcoded validate_* loop instead of selector output")

    timeout = re.search(r"timeout-minutes:\s*(\d+)", text)
    if timeout is None or int(timeout.group(1)) > 12:
        fail("fast CI job timeout must remain at 12 minutes or less")

    selector = load_selector()
    for name, tests in selector.GROUP_TESTS.items():
        if len(tests) > 6:
            fail(f"selector group {name!r} has {len(tests)} tests; split it before adding more")
        if name.lower() in {"all", "full", "everything"}:
            fail(f"selector group {name!r} is not allowed")

    samples = {
        "water": ["scripts/ui/water_tube_3d_motion.gd"],
        "block": ["scripts/game/block_puzzle_3d.gd"],
        "rescue": ["scripts/game/rescue_rush_casual.gd"],
        "ui": ["scripts/ui/premium_main_casual.gd"],
        "audio": ["scripts/core/feedback_manager.gd"],
        "monetization": ["scripts/core/store_manager.gd"],
        "docs": ["docs/README.md"],
    }
    for label, paths in samples.items():
        plan = selector.plan_for_paths(paths)
        if len(plan["tests"]) > 6:
            fail(f"single-area sample {label!r} selects {len(plan['tests'])} tests")
    if selector.plan_for_paths(samples["docs"])["needs_godot"]:
        fail("docs-only changes must not start Godot")

    print("Fast CI policy guard passed.")

if __name__ == "__main__":
    main()
