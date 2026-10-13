#!/usr/bin/env python3
"""Small reproducible sample of authored level variety; not player enjoyment."""
import json
from collections import Counter
from pathlib import Path

CHAPTERS = (1, 10, 20)
FILES = {
    "rescue_rush": "data/rescue_rush/authored/chapter_{:02d}.json",
    "block_puzzle": "data/block_puzzle/authored/chapter_{:02d}.json",
    "water_sort": "data/water_sort_curated/chapter_{:02d}.json",
}


def summarize(game, levels):
    if game == "water_sort":
        patterns = [json.dumps(x.get("t"), separators=(",", ":")) for x in levels]
        variety = len(set(patterns))
        if variety < 100:
            raise ValueError("Water Sort sampled chapter has <100 distinct boards")
        return {"distinct_boards": variety, "total": len(levels)}
    seeds = [x.get("authored_seed") for x in levels]
    if len(set(seeds)) != len(levels):
        raise ValueError(f"{game} duplicate authored seeds")
    roles = Counter(str(x.get("level_role", "")) for x in levels)
    if len(roles) < 4:
        raise ValueError(f"{game} lacks four distinct authored roles")
    if game == "rescue_rush":
        layouts = len({str(x.get("layout_archetype", "")) for x in levels})
        if layouts < 3:
            raise ValueError("Rescue Rush lacks distinct layout families")
        return {"roles": len(roles), "layout_families": layouts, "total": len(levels)}
    goals = len({str(x.get("objective", "")) for x in levels})
    if goals < 3:
        raise ValueError("Block Puzzle lacks distinct objectives")
    return {"roles": len(roles), "objective_families": goals, "total": len(levels)}


def main():
    results = {}
    for game, path_template in FILES.items():
        results[game] = {}
        for chapter in CHAPTERS:
            path = Path(path_template.format(chapter))
            levels = json.loads(path.read_text(encoding="utf-8"))["levels"]
            if len(levels) != 500:
                raise ValueError(f"{path}: expected 500 sampled levels")
            numbers = [x.get("level", x.get("l")) for x in levels]
            if len(set(numbers)) != 500:
                raise ValueError(f"{path}: duplicate level numbers")
            results[game][f"chapter_{chapter:02d}"] = summarize(game, levels)
    print(json.dumps(results, indent=2, sort_keys=True))
    print("CONTENT_SAMPLE_OK: 4500 levels across early/mid/late chapters")
    print("LIMIT: authored variety is not independent evidence of player enjoyment")


if __name__ == "__main__":
    main()
