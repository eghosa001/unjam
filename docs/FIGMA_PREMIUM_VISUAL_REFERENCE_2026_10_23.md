# UNJAM — Premium visual implementation reference (23 October 2026)

**Scope:** UNJAM only. This is an implementation reference and benchmark log, **not** a gameplay release or evidence of a 9+/10 result.

## Source design

Editable Figma file: https://www.figma.com/design/8HTM3IvH6skU5qQRsRxKgI

Current review frames are 390 × 844, retaining UNJAM's three-game identity and existing original repository SVG game art.

| Reference frame | Figma node ID | Intended existing Godot owner |
| --- | --- | --- |
| Home dark | `2:11` | `scripts/ui/premium_home_direct_levels.gd`, `figma_reference_canvas.gd` |
| Home light | `2:284` | Same Home surface, light theme |
| Choose Game | `4:2` | Shared game-selection/navigation surface |
| Rescue Rush gameplay | `4:198` | Rescue Rush gameplay scene and existing touch controls |
| Water Sort gameplay | `4:320` | Water Sort gameplay scene and existing pour controls |
| Block Puzzle gameplay | `4:402` | Block Puzzle gameplay scene and existing drag/snap controls |
| Competitor and no-regression contract | `5:9` | Review-only; no shipping node |

The source game art is from `assets/art/home/` and the visual reference reuses its vector assets; do not substitute screenshots for editable game UI or use competitor artwork. Original art, typography and material styling can be improved without changing established behavior.

## High-end comparison criteria

- **Block Blast! (Block Puzzle):** 8×8 board occupies the player's focus; legible occupancy, draggable pieces and clear target feedback. Compare actual compact- and tall-phone captures, not only the Figma board.
- **SortPuz (Water Sort):** legible glass rims, individually identifiable color layers, meaningful selection and pouring feedback; support players who cannot distinguish colors.
- **Unblock Me / arrow-escape puzzle leaders (Rescue Rush):** arrows and exits unmistakable at late-level density; no background visual competing with legality/path information.
- **Royal Match (shared visual craft only):** precise hierarchy, controlled depth, satisfying polish, and clear wins/failures. Do not borrow Royal Match's artwork or puzzle rules.

## Visual decisions for Godot translation

1. **Home:** one dominant Choose Game CTA, larger identifiable three-game art, separate Resume action, Daily and Rankings subordinate. Preserve exact target routes (game previews open level selection, Resume opens checkpoint only when valid).
2. **Both themes:** original teal/cyan/violet game accents, legible labels and consistent depth; do not turn gameplay into an overdecorated dashboard. Figma title and illustration were corrected after discovering a genuine overlap in the first design preview.
3. **HUD:** do not let coin indicator overlap move/objective counters. This was corrected in the Figma gameplay concepts. Existing in-game counter nodes and values must be verified independently, not inferred from the preview.
4. **Rescue Rush:** readable arrows, unobstructed escape lanes and clear remaining objectives, retaining existing engine behavior and deterministic level generation.
5. **Water Sort:** visible glass lip, subdued reflections, non-colour-only order/selection cues and short fluid feedback; never redraw constantly while idle.
6. **Block Puzzle:** readable 8×8 mat, bevelled but distinguishable occupied cells, clear finger-following preview and unobstructed next-piece tray.
7. **Motion:** native Godot animation/tween and low-cost static gradients; disable/reduce flourishes in reduced-motion mode. Never ship Figma screens as static interactive backgrounds.

## Implementation boundary and regressions

This branch contains **design guidance only**. No change to `project.godot`, gameplay scripts, progression, saves, monetization, existing art assets, input handling, CI or Android packaging is included here. Integrate selectively in a separate scoped code change, reviewing current runtime screenshots first. Preserve existing `390×844` reference canvas fitting, Android safe areas, icon hit targets, focus/TalkBack, light/dark themes, localization and escape navigation.

Follow [COMPETITIVE_QUALITY_STANDARD.md](COMPETITIVE_QUALITY_STANDARD.md), [PLAYER_FEEDBACK_BENCHMARK.md](PLAYER_FEEDBACK_BENCHMARK.md), [../QUALITY_GATE.md](../QUALITY_GATE.md) and the owner-locked [fast production policy](../.agents/skills/fast-production/SKILL.md). Run only directly affected tests; candidate tests include `tests/validate_home_premium_visual_hierarchy.gd`, `tests/validate_viewport_fit.gd` and the relevant single gameplay interaction/motion validator when code in that area changes. No blanket full-suite or APK builds for documentation.

## Verification ledger

| Check | Status | Evidence |
| --- | --- | --- |
| Editable Figma dark/light Home | DESIGN REVIEWED | Actual Figma renders; overlap and logo contrast defects corrected |
| Editable selector and all three gameplay reference screens | DESIGN REVIEWED | Actual Figma renders; coin/HUD collision corrected |
| Current Android behavior unchanged by this branch | VERIFIED (scope only) | This branch adds documentation, no runtime changes |
| Correctness and visual quality of implemented Godot screens | UNVERIFIED | No Godot UI code change here |
| 9+/10 quality on Android | UNVERIFIED | Device screenshots, interaction tests, frame pacing and accessibility evidence not yet collected |

**Release rule:** do not report a 9+/10 product-quality score, merge speculative visual rewrites, or publish new artwork without actual screen-by-screen comparison and the required device evidence.