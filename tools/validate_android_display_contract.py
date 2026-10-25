#!/usr/bin/env python3
"""Fail Android releases that reintroduce phone-only window/display settings.

The Godot 4.7 Android template handles platform edge-to-edge compatibility.
This guard verifies our application opts in and does not lock the activity to
portrait when exporting for tablets, foldables, or desktop-size windows.
"""
import argparse
import re
from pathlib import Path


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit("ANDROID_DISPLAY_CONTRACT_FAILED: " + message)


def check_source() -> None:
    project = Path("project.godot").read_text(encoding="utf-8")
    preset = Path("export_presets.cfg").read_text(encoding="utf-8")
    safe_area = Path("scripts/ui/device_fit.gd").read_text(encoding="utf-8")
    fit_test = Path("tests/validate_viewport_fit.gd").read_text(encoding="utf-8")

    # Godot DisplayServer.SCREEN_SENSOR (6) permits portrait and landscape.
    require(re.search(r"^window/handheld/orientation=6$", project, re.M) is not None,
            "Godot handheld orientation must be Sensor (6), not portrait-locked")
    require(re.search(r"^screen/edge_to_edge=true$", preset, re.M) is not None,
            "Android export must explicitly enable native edge-to-edge")
    require(re.search(r"^screen/immersive_mode=true$", preset, re.M) is not None,
            "Keep the existing full-screen game mode")
    require("DisplayServer.get_display_safe_area()" in safe_area and
            "safe_margins" in safe_area,
            "Full-screen content must protect controls using Android safe-area insets")
    require("Vector2i(2560,1600)" in fit_test and
            "Vector2i(1536,2048)" in fit_test and
            "Vector2i(1200,1200)" in fit_test,
            "Keep landscape, portrait-tablet, and square-window coverage")
    print("ANDROID_DISPLAY_SOURCE_OK: sensor rotation, edge-to-edge, safe area and adaptive tests")


def check_exported_manifest(path: Path) -> None:
    xmltree = path.read_text(encoding="utf-8")
    activity_name = '="com.godot.game.GodotApp"'
    at = xmltree.find(activity_name)
    require(at >= 0, "GodotApp activity missing from exported APK manifest")
    start = xmltree.rfind("E: activity (", 0, at)
    require(start >= 0, "Could not identify GodotApp activity block")
    later = xmltree.find("\n      E: activity", at)
    segment = xmltree[start:later if later >= 0 else len(xmltree)]
    orientation = re.search(r"android:screenOrientation\([^)]*\)=\(type 0x10\)0x([0-9a-fA-F]+)", segment)
    if orientation:
        # Android ActivityInfo: SENSOR=4, FULL_SENSOR=10, FULL_USER=13.
        value = int(orientation.group(1), 16)
        require(value in (4, 10, 13),
                f"exported GodotApp still has restricted orientation {value}")
    resize = re.search(r"android:resizeableActivity\([^)]*\)=\(type 0x12\)0x([0-9a-fA-F]+)", segment)
    require(resize is not None and int(resize.group(1), 16) != 0,
            "exported GodotApp is not resizable")
    require("android:appCategory" in xmltree,
            "Android game app category should remain declared")
    print("ANDROID_DISPLAY_MANIFEST_OK: GodotApp rotation is unrestricted and resizable")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, help="aapt dump xmltree output for the exported APK")
    args = parser.parse_args()
    check_source()
    if args.manifest is not None:
        check_exported_manifest(args.manifest)


if __name__ == "__main__":
    main()
