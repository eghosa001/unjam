# UNJAM — Permanent competitor benchmark and player-feedback contract

**Reviewed:** 2026-10-18. **Owner instruction:** benchmark UNJAM against category-leading games for every meaningful graphics, user-interface, puzzle-difficulty, accessibility, or release-quality change.

This document complements [the competitive 9+ standard](COMPETITIVE_QUALITY_STANDARD.md), [quality gate](../QUALITY_GATE.md) and [fast production policy](../.agents/skills/fast-production/SKILL.md). Benchmarking does **not** authorize wholesale competitive audits or unrelated tests on every small change. Check the directly changed area, capture evidence when possible, and leave unverified ratings explicitly unverified.

## Current category leaders and what to learn

| UNJAM surface | Reference | Observed design lesson | UNJAM acceptance |
| --- | --- | --- | --- |
| Rescue Rush | [Unblock Me (Kiragames)](https://play.google.com/store/apps/details?id=com.kiragames.unblockmefree) | Puzzle and target/path are visually primary; relaxed and challenge routes serve different skills. | A player can explain every arrow/exit immediately; advanced puzzles require actual dependencies and choices. |
| Water Sort | [SortPuz (Dark Halo)](https://play.google.com/store/apps/details?id=sortpuz.water.sort.puzzle.game) | Simple one-finger inputs and legible liquid boundaries with difficulty that increases naturally. | No unexpected tutorial resets after a world boundary; high-color boards remain readable and their solutions demonstrably valid. |
| Block Puzzle | [Block Blast! (HungryStudio)](https://play.google.com/store/apps/details?id=com.block.juggle) | Large 8×8 playfield, simple drag interactions and satisfying clears/combo feedback. | Precise touch release, full puzzle visibility, genuine multi-move planning, not simply harder goal labels. |
| Shared launcher | A coherent multi-game casual-puzzle home, using the same quick-to-play convention | Large previews and one dominant Choose Game action; competition/rewards are secondary to play. | On a compact Android phone, players can identify all three game types and open the intended level/game without accidental navigation. |

References are **qualitative**. Do not reproduce third-party illustrations, UI layouts, code, data, puzzles, animation files, sounds or trademarks. Use only original UNJAM art.

## Mandatory change review

For each relevant feature, record the following in the PR:

1. **Scope and reference:** Which exact UNJAM scene, puzzle mode or mechanic changed, and which top-game behavior was compared?
2. **Before:** Player complaint or objectively verified problem, with evidence (e.g., unexpectedly short proof, board already sorted, clipped button, low-contrast gesture path).
3. **After:** Implemented UI, art, board logic or puzzle content. Claim only the behavior supported by the code/test/device screenshot.
4. **Fairness:** Generated puzzles have verified legal solution paths. Disclose when a solution is an *upper bound*, not a mathematical optimum. Preserve deterministic replay, progress and purchases.
5. **Device UX:** On affected Android screens, compare visibility, touch size, contrast, readability, fluidity, reduced-motion and first-touch-to-action. Phone review is required before claiming a premium visual rating.
6. **Challenge quality:** At representative early, middle and late levels record proof length, structural dependency/branching, repetition and real completion time. A declared difficulty score by itself is insufficient.
7. **Verdict:** `VERIFIED`, `FAIL` or `UNVERIFIED` separately for CODE, CI, DEVICE and LIVE. Do not synthesize 9+/10 from only CODE and CI.

## Baseline defects observed 2026-10-18

- Water Sort levels 101–110 include several 3–9-move proofs immediately after a 19-move level 100, and many bottles start fully sorted. This is an actual first-world difficulty reset in curated content. The initial fix is a guarded deterministic remaster route that only replaces weak authored boards when a verified candidate improves both score and proof length. This is **not** a claim that all 10,000 layouts are now challenging.
- Rescue Rush previously returned the first solvable candidate despite having objective-independent structural metrics. Challenge and boss slots now compare a bounded number of solvable candidates and select on dependency depth/false routes instead of metadata labels alone.
- Block Puzzle already has 10,000 authored planning profiles and constructive solution proofs, but some challenge/boss profiles requested only one-step planning and low occupancy. Actual generator inputs are now increased selectively while recoveries remain easier.
- Compact Home previously gave each puzzle a 110×112 card with a 86×70 illustration while rankings used a 346×164 panel. The first-pass UI reallocates vertical space to the three puzzle previews, saves and larger tap surfaces. Still requires Android before/after screenshots and fresh player feedback.

## Release evidence

- Focused regression: `tests/validate_player_feedback_difficulty.gd`.
- Home layout regression: `tests/validate_home_premium_visual_hierarchy.gd`.
- Manual Android evidence: before/after native captures, one-handed touch test, TalkBack, reduced-motion check, midrange frame-time sample, first-play confusion observations.
- Observe player attempts, hint/retry rates, solving time and subjective satisfaction **only with privacy-respecting measurement**. No invented D1/D7 or completion statistics.

## Future work

The visual upgrade is not complete until gameplay assets and native screenshots meet the benchmark. Any broad rewrite of 10,000 existing authored levels requires a deliberate deterministic data-versioning/save compatibility plan and fresh proof validation. Prioritize the most frequently played levels and the observed difficulty regressions; avoid converting all levels to copies of a few harder templates.
