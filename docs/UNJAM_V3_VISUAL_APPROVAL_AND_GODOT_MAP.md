# UNJAM V3 — structural visual overhaul, preview approval

**Status:** Figma screenshots visually inspected. This is a **visual design candidate**, not a verified 9/10 in-game release.

**Permanent editable Figma:** https://www.figma.com/design/8HTM3IvH6skU5qQRsRxKgI

## Approval displays

| Display | Figma frame | Deep link |
| --- | --- | --- |
| All six current V3 screens | `20:2` | https://www.figma.com/design/8HTM3IvH6skU5qQRsRxKgI?node-id=20-2 |
| Home before/after: V2 vs V3 | `20:1154` | https://www.figma.com/design/8HTM3IvH6skU5qQRsRxKgI?node-id=20-1154 |
| V3 Home Night | `14:2` | https://www.figma.com/design/8HTM3IvH6skU5qQRsRxKgI?node-id=14-2 |
| V3 Home Day | `14:288` | https://www.figma.com/design/8HTM3IvH6skU5qQRsRxKgI?node-id=14-288 |
| V3 Choose Game | `16:2` | https://www.figma.com/design/8HTM3IvH6skU5qQRsRxKgI?node-id=16-2 |
| V3 Rescue Rush | `18:2` | https://www.figma.com/design/8HTM3IvH6skU5qQRsRxKgI?node-id=18-2 |
| V3 Water Sort | `18:125` | https://www.figma.com/design/8HTM3IvH6skU5qQRsRxKgI?node-id=18-125 |
| V3 Block Puzzle | `18:208` | https://www.figma.com/design/8HTM3IvH6skU5qQRsRxKgI?node-id=18-208 |

Screens are editable Figma layers and original UNJAM SVG assets, **not** screenshots pasted into the Figma file. The six-screen approval board contains scaled editable copies, while the individual frames retain the original 390x844 design reference. Levels and currency in mockups are sample values, not actual saved-game state.

## Actual visual changes compared with V2

**Home structure is intentionally changed** (owner authorized overriding structure for better premium appearance):

- V2: three narrow 110px cards (the game title and artwork compete for space).
- V3: three distinct **356 × 98 wide world cards** with original game-specific artwork, a visible title/caption and a dedicated progress label.
- Hero remains one neutral UNJAM identity (original illustration); Choose Game and Resume are clearly separate actions. No selected-game mascot is injected into the hero.
- Daily and Rankings are **adjacent 173 × 99 action surfaces** instead of a tall vertical stack. Both must remain legible and accessible, with their existing routes maintained.
- Home navigation stays at the bottom with profile and coin controls available at top. Dark/Light use coherent, deliberately different material palettes.
- Game selector presents 352 × 176 original-art cards per world with level browser actions, readable hierarchy and generous hit zones.
- Rescue gameplay design replaces placeholder circular chicks with `assets/art/gameplay/rescue/chick.svg`, the game's own existing art. Water and Block display clearer theme-specific boards, counters and tool bars.

**Human visual inspection corrections:** corrected hero art/headline collision in dark and light mockups; removed unintended bright line artifacts in game cards; inspected the game selector; inspected all three gameplay screens; built a side-by-side comparison board. These changes do **not** prove Android FPS, interactivity, accessibility or a quantified 9/10 score.

## Godot implementation mapping — review after design approval

Owner-authorized structural changes are expected in `scripts/ui/premium_home_direct_levels.gd`, but have not been merged or applied in production.

| Element | V3 Figma bounds (x,y,w,h) | Existing Godot owner / invariant |
| --- | --- | --- |
| Hero | 17,95,356,172 | `_add_hero`; original art `HOME_HERO_TRIO`; Choose Game and Resume remain live buttons |
| Choose Game visual | 32,218,198,44 | `_open_game_selector()`, release-only, minimum 44px hit zone |
| Resume visual | 238,218,118,44 | `_continue_selected_game()` using valid saved checkpoint |
| Rescue wide card | 17,326,356,98 | `_open_game_levels.bind("rescue_rush")` |
| Water wide card | 17,432,356,98 | `_open_game_levels.bind("water_sort")` |
| Block wide card | 17,538,356,98 | `_open_game_levels.bind("block_puzzle")` |
| Rankings | 17,651,173,99 | `_open_compete()` + real rank values, no invented ranking |
| Daily Challenge | 200,651,173,99 | `_open_daily_games()`; preserve date/completion rules |
| Bottom navigation | 14,773,362,55 | `_add_bottom_nav_reference` and all existing user routes |
| Game selector | Three cards y148/340/532, 352x176 | Existing game-specific campaign level-selection behavior |

Modify expected V2 rectangles in `tests/validate_home_premium_visual_hierarchy.gd` *only when* the actual V3 implementation changes those bounds; preserve navigation/focus, full-card hit tests, empty rank meaning, Level Select versus direct launch, locale state, edge overlaps and Android Back. Keep large-screen `_sync_wide_home_stage`, `FigmaReferenceCanvas` fitting, original assets, and lightweight static graphics; do not introduce continuously animated 3D or scene redraw solely for chrome.

For the Home design, the old authored hierarchy contract requiring Rankings above Daily must be consciously updated: the **visual structure proposes two peer cards on the same horizontal row**, not a quiet reversal. The interaction owners and state semantics remain unchanged.

## Approval and evidence requirements

- Approval here covers the **visual direction only**. On approval, implement on a dedicated non-main branch and capture **actual Godot** screenshots in both themes and at compact/tall phone sizes. Compare those directly with Figma and category leaders.
- Run directly affected tests under `.agents/skills/fast-production/SKILL.md` rather than all project tests. Keep validation controls, never gut them to accommodate the redesign.
- Ensure play state, coins, rank, Daily completion, touch inputs, localization, accessibility, Buy/Resume routes and SaveManager persistence do not regress.
- Do not claim 9+/10 for mobile visual quality without DEVICE evidence. Keep CODE, CI, DEVICE, LIVE `VERIFIED`/`UNVERIFIED`/`FAIL` status separate.
- Preserve V2 and earlier Figma frames for rollback and side-by-side review.

**No Godot runtime files were modified by this design-stage pass.**
