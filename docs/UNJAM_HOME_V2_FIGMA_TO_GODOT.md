# UNJAM Home V2 — Figma to Godot implementation checklist

**Status: DESIGN-REVIEWED, NOT CODE-IMPLEMENTED.** The owner requested a premium Home redesign and a precise Godot handoff, using Figma. This specification is limited to UNJAM; no gameplay logic, assets, save data or production configuration are changed by this document.

## Editable premium visual designs

Source: https://www.figma.com/design/8HTM3IvH6skU5qQRsRxKgI

| Screen / reference | Figma node | Visual review |
| --- | --- | --- |
| Home V2 Midnight | `8:2` | Inspected at 390×844; hero and ranking CTA fixed |
| Home V2 Porcelain | `8:296` | Inspected at 390×844; mirrored corrections |
| Godot implementation map | `12:2` | Inspected at readable full-sheet scale |
| Earlier Home draft, dark / light | `2:11` / `2:284` | Preserved for visual comparison |
| Three gameplay mode concepts | `4:198`, `4:320`, `4:402` | Previous design references, NOT runtime implementations |

This design review compared actual Figma renders with category-leader image references: Block Blast! (high-contrast tiles, uncluttered primary board), SortPuz (clearly separated liquid layers), and Royal Match (polished visual hierarchy and strong hero). Reuse *principles*, not competitor art. The Hero and game-card art are UNJAM's original editable SVG vectors.

### Precise Home V2 visual geometry (390×844)

| Element | Proposed reference bounds | Existing source owner |
| --- | --- | --- |
| Header profile | x199, y24; 44×44 | `_build_reference_home` / `_open_profile` |
| Header coin affordance | x257, y24; 110×44 | `_build_reference_home` / `_open_shop` |
| Hero surface | x18, y95; 354×221 | `_add_hero` |
| Trio illustration | x220, y110; 145×151 | `_add_hero` / `HOME_HERO_TRIO` |
| Choose Game visual control | x34, y271; 200×44 | `_add_hero` / `_open_game_selector` |
| Resume visual control | x243, y271; 112×44 | `_add_hero` / `_continue_selected_game` |
| Three game cards | x20, x140, x260; y372; 110×166 each | `_add_game_showcase` / `_open_game_levels.bind(id)` |
| Rankings surface | x20, y552; 350×108 | `_add_rank_summary` / `_open_compete` |
| Daily surface | x20, y679; 350×75 | `_add_daily_feature` / `_open_daily_games` |
| Bottom navigation | x15, y773; 360×56 | `_add_bottom_nav_reference` |

Figma visual materials are *reference geometry*. Runtime hit rectangles may be larger than painted buttons; hit areas must be at least 44×44 and must **not** overlap adjacent control ownership. For Daily and ranking controls, preserve the existing larger functional tap surfaces even when the Figma cosmetic button is smaller.

## Exact Godot translation

- Primary visual owner: `scripts/ui/premium_home_direct_levels.gd`. Keep `build_home_launcher()` plus existing named buttons and signals, including Home, profile, coins, rankings, Daily and each game's Level Select. Do **not** replace those controls with a rasterized screenshot or a UI-only illustration.
- Existing layout/cached material helpers: `scripts/ui/figma_reference_canvas.gd`, especially `REFERENCE_SIZE = Vector2(390,844)`, `set_rect`, `rounded_gradient3`, `flat_gloss`, and `_fit_reference_canvas`. Prefer static cached nine-slice materials and original `assets/art/home/*.svg` rather than new continuously animated shaders or nested 3D viewports.
- Preserve responsive `_sync_wide_home_stage` logic, notch/safe-area handling and the separate tablet/landscape Home. The Figma 390×844 design does **not** prove tablet quality or authorize scaling up a phone screenshot.
- All UI controls remain live `Button` nodes with `ACTION_MODE_BUTTON_RELEASE`, correct `focus_mode`, accessible names, a minimum 44px target, and theme-specific focus/pressed/disabled states. Never let the next scene catch the originating touch-up event.
- Figma previews use Inter as a design approximation. UNJAM currently styles native text with `Unjam3DTheme` and `ThemeDB.fallback_font`. Match final runtime text measurements on device; do not silently switch to an unlicensed or unavailable font.
- Keep original brand and per-game accents: Rescue teal/green, Water cyan, Block violet. Resist global glow and shadow inflation. Preserve static idle rendering and reduced-motion settings.
- **Preserve the production Home content order: Rankings above Daily.** This difference was identified and fixed in Figma V2 before handing off.
- Existing tests currently assert specific old rectangles (e.g., hero `Rect2(21,126,346,168)`, cards `Rect2(21,344,110,160)`). When implementing the approved V2 layout, update *only those affected expected bounds* alongside the actual Godot code; do not bypass, delete or loosen the assertions. Maintain all functional assertions.

## Scoped implementation sequence

1. Capture current **actual Godot** Home at compact 432×936 and 540×960, dark and light; also inspect one tall-phone and one tablet surface. Establish pixel/interaction baseline, not Figma assumptions.
2. Implement visual-only Home V2 adjustments in `premium_home_direct_levels.gd`, with the unchanged existing button callbacks and stable named nodes. Start with hero, then cards, rankings, Daily, navigation.
3. Match material/hierarchy against V2 source while inspecting actual render. Maintain all essential text at practical readable sizes; protect layout against localized text, long scores and actual level 10,000.
4. Update `tests/validate_home_premium_visual_hierarchy.gd` alongside visual geometry, preserving its checks for routing, rank truthfulness, artwork visibility, focus and no touch-through. Run this focused validator. If viewport fitting or touch bounds change, run only the directly affected `tests/validate_viewport_fit.gd` and targeted navigation test permitted by `.agents/skills/fast-production/SKILL.md`.
5. Review **before/after native Android** captures against Royal Match visual craftsmanship (not art), Block Blast! readability and the UNJAM Home V2. Assess quiet background, button states, one-handed hit zones, TalkBack, empty/loading states, portrait and tablet variants.
6. Record `CODE`, `CI`, `DEVICE`, `LIVE` separately, using `VERIFIED`, `FAIL` or `UNVERIFIED`. Do not report 9+/10 from code, Figma previews or green checks alone.

## Completion and regression barriers

- Choose Game opens chooser. Three Home game cards open **their own level-select** screens, not gameplay. Resume uses the actual valid checkpoint. Profile, coins, Rankings and Daily open intended destinations.
- Navigation remains consistent on Android Back, tap release, rapid screen transitions and loading cancellation; no orphaned overlays.
- SaveManager/purchases/progression/10,000-level level data unaffected. Never edit gameplay, monetization or release settings as a side effect of visual polish.
- No clipped controls, tiny labels, inaccessible contrast, unchanged-state buttons masquerading as clickable affordances, screen-wide images intercepting touch, battery-draining idle redraw or false ranking values.
- Physical device evidence required before declaring premium 9+/10; otherwise `UNVERIFIED`.

**Present status:** Figma concept and checklist complete, visuals reviewed and corrected; Godot implementation and physical-device quality remain **UNVERIFIED**.
