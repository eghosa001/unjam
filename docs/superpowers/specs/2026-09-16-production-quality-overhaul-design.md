# UNJAM Production Quality Overhaul Design

## Goal
Raise UNJAM from a strong closed-beta puzzle collection to a production-ready mobile game without destabilizing its existing campaign generation or gameplay logic.

## Strategy
Use staged consolidation rather than a rewrite or another layer of polish scripts. Preserve the active game scenes and proven generation logic, introduce authoritative shared systems for motion/feedback/presentation, then migrate active code paths onto those systems. Remove obsolete code only after reference checks prove it is unreachable.

## Non-negotiable constraints
- Preserve all existing solvable/playable campaign behavior and the 10,000-level generation contracts.
- Never animate or shake full-screen roots for gameplay impact; punch only board/gameplay-local containers.
- Keep the app portrait-first and compatible with Godot GL Compatibility rendering.
- Keep monetization fail-closed: no paid entitlement is granted until purchase verification/reconciliation succeeds.
- Do not invent production AdMob IDs, Play product metadata, verification endpoints, signing credentials, or secrets.
- Reduced-motion mode must preserve gameplay meaning while suppressing nonessential motion.
- Fast-animation mode must shorten animation latency without skipping state transitions.
- UI polish must reduce the number of independent controllers mutating the same surface.

## Architecture

### 1. Motion system
Create `scripts/ui/motion_system.gd` as the single motion vocabulary. It owns named durations and easing presets and exposes helpers for fade-in, press anticipation, local punch, pop, and hit-stop. It reads `SaveManager.data["reduce_motion"]` and `SaveManager.data["fast_animation"]` so all games use the same accessibility/performance behavior.

`MotionDirector` becomes a transition observer/adapter rather than defining its own motion constants. Where possible, navigation changes become event-driven rather than per-frame polling.

### 2. Feedback system
Extend `FeedbackManager` from generic tones (`tap`, `blocked`, `escape`, `effect`, `rescue`) into semantic game events: navigation, lift, drop, pour start/end, invalid move, line clear, combo tier, completion. Cache generated tones so recurring effects do not allocate a new WAV on every interaction. Haptics remain restrained: error/completion/large-clear events only unless the user explicitly enables stronger feedback later.

### 3. Procedural materials and background
Preserve procedural drawing, but standardize depth cues: contact shadows, top-light/bottom-depth color ramps, moving restrained specular accents, glass/liquid highlights, and scalable particle budgets. Enhance `PremiumBackdrop` instead of adding another backdrop system. Background work scales by quality tier and respects reduced motion.

### 4. Game-specific motion
- Rescue Rush: anticipation before movement, smooth exit/completion sequencing, result guard that never reveals success before the final moving object clears, local board punch and scalable rescue/combo celebration.
- Water Sort: lip-correct stream geometry, lift/travel/tip/pour/return phases using shared durations, quicker concurrent input scheduling, liquid/glass depth, completion feedback, fast-animation path.
- Block Puzzle: drag smoothing, placement anticipation, contact shadow, local landing punch, animated tray reflow, traveling line clear, debris, combo escalation, no whole-screen movement.

### 5. Shell consolidation
Reduce simultaneous presentation ownership in `Main.tscn`. Keep one owner each for navigation transitions, background/theme, overlays/modals, and touch enhancement. Existing specialized controllers may remain temporarily but lose overlapping responsibilities as behavior migrates.

### 6. Accessibility and device fit
Add saved `reduce_motion` and `fast_animation` preferences. Add safe-area aware padding helpers for phone cutouts/gesture areas where supported, preserve minimum touch targets, avoid disabling focus globally, and keep text/layout stable under common aspect ratios. Automated visual checks should cover multiple portrait viewport sizes rather than only 1080×1920.

### 7. Performance
Replace unnecessary high-frequency scene-tree polling with signals/change detection. Cache synthesized SFX, scale background particle counts by visual quality, and avoid allocation-heavy effects in tight interaction loops. Maintain current adaptive visual quality behavior.

### 8. Monetization hardening
Finish Android billing state management without inventing provider credentials. The bridge must expose product query results, pending/purchased/cancelled/error states, and purchase restore completion only after verification/reconciliation. Store UI must prefer localized prices returned by Play. Ads and real purchases remain disabled/unavailable when required production configuration is missing.

### 9. Release engineering
Strengthen CI to fail on missing SDK/tool installation instead of masking failures, modernize deprecated actions, keep debug artifacts for test workflows, and document a separate release-signed/Play-App-Signing production path. Production release checks must explicitly reject blank required monetization configuration when monetization is enabled.

## Testing
Every behavior-changing batch follows test-first development. Existing gameplay/generation/motion/visual tests stay green. New tests cover shared motion preferences, semantic feedback API availability, completion sequencing, reduced-motion behavior, fast-animation timing bounds, billing pending/restore states, and multi-viewport layout smoke checks.

## Definition of done
The overhaul is complete when active scenes use the shared motion vocabulary, recurring SFX are cached, the three games have synchronized semantic feedback and polished local motion, background work adapts to accessibility/performance settings, overlapping presentation ownership is materially reduced, billing state handling is production-safe apart from externally supplied credentials/SDK setup, CI/release checks are stricter, and the full automated suite passes on the overhaul branch.