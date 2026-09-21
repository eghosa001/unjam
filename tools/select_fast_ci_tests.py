#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

GROUP_TESTS = {
    "ui": [
        "validate_requested_polish_contract",
        "validate_reported_polish_regressions",
        "validate_uiux_regressions",
        "validate_viewport_fit",
        "validate_transition_ownership",
        "validate_theme_integrity",
    ],
    "water": [
        "validate_reported_polish_regressions",
        "validate_compact_gameplay_stack",
        "validate_daily_and_late_water_runtime",
        "validate_water_liquid_continuity",
        "validate_water_pour_arc",
    ],
    "block": [
        "validate_reported_polish_regressions",
        "validate_compact_gameplay_stack",
        "validate_block_visual_integrity",
        "validate_block_single_touch_owner",
    ],
    "rescue": [
        "validate_reported_polish_regressions",
        "validate_compact_gameplay_stack",
        "validate_gameplay_interactions",
        "validate_rescue_token_render_lifecycle",
    ],
    "progression": [
        "validate_gameplay_interactions",
        "validate_progression_transitions",
    ],
    "daily": [
        "validate_progression_transitions",
        "validate_daily_and_late_water_runtime",
        "validate_collection_daily_value",
    ],
    "audio": [
        "validate_soothing_audio_palette",
        "validate_feedback_manager_event_driven_music",
    ],
    "monetization": [
        "validate_monetization",
        "validate_shop_catalog_ui",
        "validate_restore_purchase_flow",
        "validate_coin_economy",
    ],
    "fallback": [
        "validate_reported_polish_regressions",
        "validate_gameplay_interactions",
        "validate_progression_transitions",
    ],
}

CODE_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".cfg", ".py", ".sh"}
DOC_PREFIXES = ("docs/",)
DOC_SUFFIXES = {".md", ".txt", ".rst"}

def add(groups: set[str], *values: str) -> None:
    groups.update(values)

def classify_path(path: str, groups: set[str], visual: set[str], explicit_tests: set[str]) -> bool:
    p = path.lower()
    suffix = Path(p).suffix

    if p.startswith("tests/validate_") and p.endswith(".gd"):
        explicit_tests.add(Path(p).stem)
        return True
    if p == "tests/capture_visual_audit.gd":
        visual.update({
            "home", "games", "levels", "collection", "daily", "settings",
            "shop", "rescue", "water", "block", "tutorial", "result"
        })
        return True

    if p.startswith(DOC_PREFIXES) or suffix in DOC_SUFFIXES or p in {"license", "readme"}:
        return False
    if p.startswith(".github/") or p == "tools/select_fast_ci_tests.py":
        return False

    is_code = suffix in CODE_SUFFIXES or p.startswith(("scripts/", "scenes/", "addons/", "data/"))
    if not is_code:
        return False

    if any(token in p for token in ("water_sort", "water_tube", "/water_", "water_")):
        add(groups, "water")
        visual.add("water")
    if any(token in p for token in ("block_puzzle", "/block_", "block_")):
        add(groups, "block")
        visual.add("block")
    if any(token in p for token in ("rescue_rush", "campaign_generator.gd", "/rescue_", "rescue_")):
        add(groups, "rescue")
        visual.add("rescue")

    if p.startswith("scripts/systems/") and "premium_visuals" in p:
        add(groups, "ui")
        visual.update({"games", "levels", "collection", "daily", "settings", "shop"})

    if p.startswith("scripts/ui/"):
        game_specific_ui = bool(groups.intersection({"water", "block", "rescue"}))
        monetization_ui = any(token in p for token in ("monetization_hub", "shop_", "purchase_"))
        if monetization_ui:
            add(groups, "monetization")
            visual.add("shop")
        elif not game_specific_ui:
            add(groups, "ui")
            if p.endswith(("figma_reference_canvas.gd", "unjam_3d_theme.gd")):
                visual.update({
                    "home", "games", "levels", "collection", "daily", "settings",
                    "shop", "rescue", "water", "block", "tutorial", "result"
                })
            elif "premium_home" in p:
                visual.add("home")
            elif "premium_live_hub" in p:
                visual.add("games")
            elif p.endswith(("premium_main_casual.gd", "premium_main.gd")):
                visual.update({"home", "levels", "collection", "daily", "settings"})
            elif "ux_shell" in p or "tutorial" in p:
                visual.add("tutorial")
            elif "premium_result_overlay" in p or "result" in p:
                visual.add("result")
            elif "unjam_3d_backdrop" in p or "premium_visuals" in p:
                visual.update({"games", "levels", "collection", "daily", "settings", "shop"})
            else:
                visual.add("home")

    if any(token in p for token in (
        "multi_game_manager", "progression", "save_manager", "level_pack",
        "level_select", "world_progress", "campaign"
    )):
        add(groups, "progression")

    if any(token in p for token in ("daily", "collection_daily")):
        add(groups, "daily")

    if any(token in p for token in ("feedback_manager", "audio", "music", "sound")):
        add(groups, "audio")

    if any(token in p for token in (
        "monetization", "admob", "billing", "store_manager", "privacy_manager",
        "economy", "purchase", "coin_"
    )):
        add(groups, "monetization")

    # Generic gameplay/core changes still get a small conservative contract set.
    if p.startswith(("scripts/game/", "scripts/core/")) and not groups:
        add(groups, "fallback")

    # Project/scene/plugin changes at least require import + boot.
    return True

def plan_for_paths(paths: list[str]) -> dict[str, object]:
    groups: set[str] = set()
    visual: set[str] = set()
    explicit_tests: set[str] = set()
    needs_godot = False
    release_contract = False

    for raw in paths:
        path = raw.strip()
        if not path:
            continue
        code_related = classify_path(path, groups, visual, explicit_tests)
        needs_godot = needs_godot or code_related
        low = path.lower()
        if (
            low in {"project.godot", "export_presets.cfg", "tools/validate_release_contract.py"}
            or low.startswith("addons/")
            or any(token in low for token in ("monetization", "admob", "billing", "purchase_verification"))
        ):
            release_contract = True

    tests: list[str] = []
    for group in sorted(groups):
        tests.extend(GROUP_TESTS[group])
    tests.extend(sorted(explicit_tests))
    tests = list(dict.fromkeys(tests))

    return {
        "groups": sorted(groups),
        "tests": tests,
        "visual": sorted(visual),
        "needs_godot": needs_godot or bool(tests) or bool(visual),
        "release_contract": release_contract,
    }

def git_changed_files(base: str, head: str) -> list[str]:
    def valid(ref: str) -> bool:
        if not ref or set(ref) == {"0"}:
            return False
        return subprocess.run(
            ["git", "cat-file", "-e", f"{ref}^{{commit}}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        ).returncode == 0

    if not valid(head):
        head = "HEAD"
    if not valid(base):
        probe = subprocess.run(
            ["git", "rev-parse", f"{head}^"],
            capture_output=True,
            text=True,
            check=False,
        )
        base = probe.stdout.strip() if probe.returncode == 0 else ""

    if not base:
        out = subprocess.check_output(["git", "ls-tree", "-r", "--name-only", head], text=True)
    else:
        out = subprocess.check_output(["git", "diff", "--name-only", f"{base}...{head}"], text=True)
    return [line for line in out.splitlines() if line.strip()]

def emit_github_output(path: str, plan: dict[str, object], changed: list[str]) -> None:
    values = {
        "tests": " ".join(plan["tests"]),
        "groups": ",".join(plan["groups"]),
        "visual_scope": ",".join(plan["visual"]),
        "needs_godot": str(bool(plan["needs_godot"])).lower(),
        "release_contract": str(bool(plan["release_contract"])).lower(),
        "changed_count": str(len(changed)),
    }
    with open(path, "a", encoding="utf-8") as fh:
        for key, value in values.items():
            fh.write(f"{key}={value}\n")

def self_test() -> None:
    cases = [
        (["docs/README.md"], [], [], False),
        (["scripts/game/water_sort_casual.gd"], ["water"], ["water"], True),
        (["scripts/ui/water_tube_3d_motion.gd"], ["water"], ["water"], True),
        (["scripts/game/block_puzzle_3d.gd"], ["block"], ["block"], True),
        (["scripts/ui/ux_shell_casual.gd"], ["ui"], ["tutorial"], True),
        (["scripts/ui/premium_result_overlay.gd"], ["ui"], ["result"], True),
        (["scripts/ui/premium_live_hub_3d.gd"], ["ui"], ["games"], True),
        (["scripts/ui/premium_main_casual.gd"], ["ui"], ["collection", "daily", "home", "levels", "settings"], True),
        (["scripts/systems/premium_visuals.gd"], ["ui"], ["collection", "daily", "games", "levels", "settings", "shop"], True),
        (["scripts/ui/monetization_hub_3d.gd"], ["monetization"], ["shop"], True),
        (["scripts/core/feedback_manager.gd"], ["audio"], [], True),
        (["scripts/core/store_manager.gd"], ["monetization"], [], True),
        (["tests/validate_viewport_fit.gd"], [], [], True),
        (["tools/select_fast_ci_tests.py"], [], [], False),
        ([".github/workflows/godot-ci.yml"], [], [], False),
    ]
    for paths, groups, visual, godot in cases:
        plan = plan_for_paths(paths)
        assert plan["groups"] == groups, (paths, plan)
        assert plan["visual"] == visual, (paths, plan)
        assert plan["needs_godot"] is godot, (paths, plan)
    explicit = plan_for_paths(["tests/validate_viewport_fit.gd"])
    assert explicit["tests"] == ["validate_viewport_fit"], explicit
    print("select_fast_ci_tests self-test passed")

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="")
    parser.add_argument("--head", default="HEAD")
    parser.add_argument("--github-output")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return

    changed = git_changed_files(args.base, args.head)
    plan = plan_for_paths(changed)
    print("Changed files:")
    for path in changed:
        print(f"  {path}")
    print("Selected groups:", ",".join(plan["groups"]) or "(none)")
    print("Selected tests:", " ".join(plan["tests"]) or "(none)")
    print("Visual scope:", ",".join(plan["visual"]) or "(none)")
    if args.github_output:
        emit_github_output(args.github_output, plan, changed)

if __name__ == "__main__":
    main()
