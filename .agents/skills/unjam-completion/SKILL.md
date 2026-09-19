---
name: unjam-completion
description: End-to-end completion, QA, polish, monetization, security, performance, Android/Google Play readiness, and release workflow for the eghosa001/unjam Godot game collection. Use whenever the user asks to complete, continue, finish, audit, polish, test, fix, benchmark, productionize, release, or review UNJAM, Rescue Rush, Water Sort, or Block Puzzle. Do not use for unrelated repositories.
---

# UNJAM Completion Skill

Own the UNJAM project from the current repository state to the strongest release-ready state that can be achieved with the available tools. Treat “complete” as a measurable quality gate, not as “the requested file was changed.”

Repository: `eghosa001/unjam`  
Primary branch: `main`  
Engine: Godot 4.7.2, compatibility renderer  
Target: portrait-first Android casual puzzle collection  
Games: Rescue Rush, Water Sort, Block Puzzle  
Campaign target: deterministic 10,000 levels per game

## Core operating rules

1. Inspect before changing. Read the repository structure, README, release checklist, current branch/PR state, workflows, relevant scenes/scripts, tests, recent CI, and current production configuration.
2. Preserve working functionality. Prefer focused fixes over rewrites. Do not replace stable systems merely to make the code look different.
3. Work iteratively until completion gates pass. After each meaningful batch: run the smallest relevant tests first, then broader validation.
4. Add only short, precise automated tests that protect the bug or invariant being changed. Do not create irrelevant test bulk.
5. Never claim a visual, gameplay, monetization, build, backend, or release gate passed without evidence.
6. Do not hide failures. Fix them where possible; otherwise record the exact blocker, evidence, and owner action.
7. Never commit secrets, keystores, passwords, service-account JSON, private purchase tokens, production credentials, or other sensitive values.
8. Keep production behavior fail-closed for ads, purchases, consent, and server-side purchase verification.
9. Use a branch for substantial work. Keep commits logically grouped and review the final diff before merging.
10. Do not stop at the first green test run. Perform the visual, interaction, performance, monetization, release, and production-readiness passes below.
11. If the user says “continue,” resume from the last unfinished completion gate instead of restarting the audit.
12. External/account-side tasks must not block code-side completion. Finish everything possible in the repository, then report the remaining manual tasks separately.

## Persistent completion state

Maintain `docs/UNJAM_COMPLETION_STATUS.md` while doing substantial completion work so another session can resume without depending on chat history.

Create it if missing. Keep it compact and update it after each meaningful batch with:

- exact branch and latest commit reviewed
- current phase/gate
- P0/P1/P2/P3 issue inventory and status
- fixes completed
- tests run and their results
- screenshots/device states reviewed
- performance measurements that matter
- monetization/backend/release findings
- owner-only blockers
- next unfinished action

Do not turn this file into a diary. Replace stale status with the current truth. When starting a new run, read it but verify important claims against the repository and current CI before trusting them.

## Tool strategy

Use the best available tools instead of simulating them.

- GitHub: repository inspection, branches, commits, PRs, CI/workflows, artifacts, release checks, and merging.
- Godot/runtime environment: import, headless validators, rendered screenshots, boot smoke, gameplay execution, Android exports, and performance checks.
- Figma: use when a composed screen or design system needs a deliberate redesign before implementation; do not create Figma work for trivial spacing fixes.
- Security tooling: scan changed code, dependencies, secrets exposure, unsafe network/purchase handling, and release configuration.
- Web research: when comparing against current premium casual puzzle games or current Google Play/Android requirements, research fresh sources rather than relying on stale assumptions.
- Backend/cloud tooling: inspect the actual backend used by the repository. Do not assume Supabase if the project uses another backend.

When a capability is unavailable, use the repository’s existing validators and CI, and clearly identify what remains unverified.

# Completion loop

Repeat this loop until the definition of done is satisfied.

## 1. Establish the baseline

Inspect:

- `README.md`
- `RELEASE_CHECKLIST.md`
- `project.godot`
- `export_presets.cfg`
- `.github/workflows/`
- `scenes/`
- `scripts/core/`
- `scripts/game/`
- `scripts/ui/`
- `scripts/systems/`
- `backend/`
- `tests/`
- `tools/`
- `assets/`
- recent open PRs, branches, commits, failed/successful CI runs and downloadable visual/build artifacts

Build a current issue inventory with severity:

- P0: crash, data loss, security/payment flaw, broken launch/build, corrupt progression
- P1: broken gameplay, inaccessible screen/control, monetization exploit, severe layout defect, major performance problem
- P2: quality/polish inconsistency, weaker animation/audio/feedback, minor responsive issue
- P3: cleanup, maintainability, low-risk polish

Do not rely on old issue lists when the code has moved on. Reproduce current problems.

## 2. Run baseline validation

At minimum run the project import and the relevant existing validators. Prefer the repository’s own test runners and CI commands.

Representative checks include:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/validate_motion_quality.gd
godot --headless --path . --script res://tests/validate_transition_ownership.gd
godot --headless --path . --script res://tests/validate_difficulty_curves.gd
godot --headless --path . --script res://tests/validate_monetization.gd
godot --headless --path . --script res://tests/validate_robustness.gd
godot --headless --path . --script res://tests/validate_campaign.gd
godot --headless --path . --script res://tests/validate_gameplay_interactions.gd
godot --headless --path . --script res://tests/validate_restore_purchase_flow.gd
godot --headless --path . --script res://tests/validate_viewport_fit.gd
godot --headless --path . --quit-after 5
```

Also run the complete grouped validator set used by CI when feasible.

If a validator is stale or tests an obsolete behavior, repair the validator and explain why; do not simply delete or weaken it to get green.

# Product-quality audit

## 3. Audit every user-visible surface

Create a screen/state inventory and inspect all reachable states, not only the home screen.

Include at least:

- launch/splash/boot
- onboarding or first-run state
- home/launcher
- game selection
- Rescue Rush
- Water Sort
- Block Puzzle
- level selection for every game
- pause
- result/win/fail overlays
- hint/undo/restart flows
- daily challenge surfaces
- Live/retention surfaces
- collection/reward surfaces
- currency/reward feedback
- store/IAP surfaces
- rewarded-ad flows
- settings
- privacy/consent/privacy options
- restore purchase
- offline/error/loading/empty states
- locked/unlocked world states
- milestone/boss/checkpoint states
- back-navigation and Android lifecycle resume states

For each surface inspect default, pressed, disabled, selected, loading, success, failure, modal-open, long-text, small-screen and large-screen states where applicable.

## 4. Premium UI/UX quality bar

Benchmark the current build against polished contemporary casual puzzle games in the same categories. Research current references when doing a serious comparison. Compare standards and interaction quality; never copy protected art, sounds, layouts, branding, levels, or assets.

The target feel is:

- immediately readable
- bright, inviting and premium rather than developer-tool-like
- strong visual hierarchy
- large comfortable controls
- smooth, purposeful motion
- coherent spacing
- consistent component language
- polished game surfaces
- satisfying feedback
- minimal friction to start playing
- monetization that does not cheapen the experience

### Typography

Reject:

- tiny body text
- low-contrast labels
- cramped line height
- inconsistent font weights/sizes
- text that scales poorly or clips

Prefer a mobile-readable hierarchy. Critical buttons, level numbers, scores, game labels and navigation must remain legible on compact phones without leaning in or zooming.

### Touch targets and controls

All meaningful touch controls must be comfortably tappable. Use roughly 48 dp as a minimum target where practical, with larger primary game/navigation buttons. Back buttons, game buttons, tabs, reward buttons, settings controls and level cells must not feel miniature.

Validate:

- visible target matches hitbox
- no overlapping hit regions
- no accidental double activation
- no hidden controls behind safe areas
- immediate pressed feedback
- disabled controls look disabled
- input remains correct during animation

### Layout and screen fit

UNJAM is portrait-first. Check at least representative compact, normal and tall Android aspect ratios, including the project’s 540×960 override and the 1080×1920 design viewport.

Check:

- no clipping
- no overlapping panels
- no off-screen buttons
- no text truncation that hides meaning
- correct safe-area handling
- no modal extending beyond viewport
- level grids fit and scroll naturally
- game boards are large enough to play
- bottom navigation does not cover content
- keyboard/system overlays do not corrupt layout
- transitions do not leave old screens visible underneath

Prefer anchors, containers and responsive sizing over hard-coded pixel positioning when practical.

## 5. Home and navigation polish

The home screen must feel like a finished game launcher, not a debug menu.

Require:

- clear game-first hierarchy
- strong UNJAM identity
- obvious primary “play” paths
- visually distinct Rescue Rush, Water Sort and Block Puzzle cards/entry points
- polished Live/daily/reward entry points
- restrained secondary controls
- coherent background composition
- no dead space that makes the layout feel unfinished
- smooth navigation transitions
- consistent back behavior
- fast route to resume the last meaningful game state where appropriate

Avoid excessive card nesting, tiny icons, visually weak backgrounds, or an interface dominated by settings/utility controls.

# Game-specific quality

## 6. Rescue Rush

Audit:

- directional movement correctness
- containment/collision correctness
- rescue/goal detection
- chain reactions
- visual direction cues
- blocked vs valid moves
- hint correctness
- restart/undo semantics
- camera framing
- level readability
- animation ownership
- 10,000-level generation/progression
- boss/milestone difficulty
- no impossible deterministic levels unless deliberately identified and handled

Play representative early, middle, late, milestone and boss samples; do not infer campaign quality only from generator tests.

## 7. Water Sort

Audit:

- legal/illegal pour logic
- contiguous color-segment transfer
- capacity rules
- win detection
- undo/restart/hint
- tube selection feedback
- pour trajectory
- liquid appearance
- motion pacing
- concurrent/tween state safety
- interaction while animation is active
- no frozen input after interrupted transitions
- level generation/solvability/difficulty
- 10,000-level progression

The game should allow responsive interaction without corrupting state. If multitasking during motion is supported, serialize logical state safely while keeping the experience fluid.

## 8. Block Puzzle

Audit aggressively because tray/drag rendering defects are highly visible.

Check:

- piece tray never duplicates visually
- dragging a piece does not leave a ghost/double
- board preview exactly matches final placement
- placement hit testing is stable
- line clearing order is correct
- score/combo feedback is clear
- tray refresh is atomic
- no stale piece remains after placement
- game-over detection is correct
- constructive solvability/difficulty behavior matches design
- piece shapes remain readable at all supported resolutions
- bot/calibration tests remain meaningful

Test repeated rapid drag/drop, cancel, near-edge placement, multi-line clears, orientation changes only if supported, pause/resume during drag, and low-FPS behavior.

# Visual rendering and art direction

## 9. 3D / glossy casual-game finish

Where 3D is used, prefer polish from materials, lighting and edge treatment over unnecessarily dense geometry.

Audit and improve:

- small bevels/chamfers on hard edges
- rounded silhouettes where suitable
- deliberate roughness/metallic/specular values
- clean edge highlights
- coherent key/fill/rim lighting
- soft contact shadows
- ambient separation from background
- controlled reflections
- color consistency
- subtle depth cues
- particles only when they add feedback
- no harsh default-engine look
- no flat unlit plastic unless stylistically intentional

Keep shaders/materials mobile-friendly. Measure the cost of lights, transparency, particles, post-processing and 3D rebuilds.

## 10. Backgrounds and presentation

Backgrounds must look composed, not like a placeholder image behind UI.

Check:

- focal area supports foreground readability
- contrast remains strong
- no noisy detail behind text
- depth layers/parallax are restrained
- transitions between menus and games feel related
- light/dark states are intentional
- brightness is pleasant on mobile
- game board remains the visual priority during play

# Motion, feedback and audio

## 11. Motion

Every important action should have feedback, but avoid motion clutter.

Audit:

- screen enter/exit
- button press
- selected state
- piece/tube/vehicle movement
- win/lose
- line clear/rescue/sort completion
- reward/coin changes
- modal presentation
- level unlock
- milestone/boss presentation
- ad/purchase return to gameplay

Require:

- consistent easing
- no competing tweens on the same property
- transitions cancel/replace safely
- no input lock left behind
- no flicker/teleport on first 3D frame
- no double animations caused by repeated events
- reduced unnecessary animation during idle to preserve battery/performance

## 12. Audio and haptics

Treat sound as part of premium feel.

Audit:

- calm/soothing background music suitable for repeated puzzle play
- seamless loops
- no clipping
- no abrupt volume jumps
- sensible music/SFX mix
- distinct but coherent interaction, placement, pour, clear, rescue, win and reward sounds
- no harsh/repetitive high-frequency effects
- settings persist
- audio resumes correctly after backgrounding
- appropriate ducking/fades
- haptic feedback is restrained and optional where implemented

Only use audio/assets with clear rights suitable for commercial release. Do not copy competitor audio.

# Progression, challenge and retention

## 13. 10,000-level progression per game

Do not validate only that level numbers exist. Validate the difficulty curve.

Sample across the campaign:

- tutorial/opening
- 10–25
- milestone 25
- world 1 end / 100 boss
- 250
- 500
- 1,000
- 2,500
- 5,000
- 7,500
- 10,000

Include deterministic randomized sampling across bands.

Require:

- early levels teach without becoming trivial for too long
- difficulty increases over time but retains local variation
- milestone levels feel special
- boss levels produce meaningful spikes
- no long flat sections
- no impossible spikes
- assistance systems do not destroy challenge
- generated content remains varied enough to avoid obvious repetition

Use exact/constructive solvers where the repository provides them.

## 14. Daily challenges and retention

Daily game content must be genuinely available and discoverable.

Verify:

- daily challenge appears when expected
- correct date rollover
- deterministic daily seed where intended
- no duplicate reward exploit
- timezone/date changes handled safely
- streak logic
- claim state persistence
- offline behavior
- reward balance
- Live/retention surface has a reason to exist
- collection systems have meaningful content and progression rather than being an empty grind

If a “collection” costs player time/currency, justify it with visible goals, unlocks, cosmetics, progression, bonuses, or meaningful completion value.

# Economy and monetization

## 15. Economy

Audit all coin sources/sinks and progression rewards.

Check:

- no infinite reward exploit
- no negative balances
- atomic reward grants
- hint price is communicated
- hint cost/rewarded-ad fallback behaves as designed
- reward amounts do not trivialize progression
- IAP coin packs are distinguishable
- reset behavior preserves store-owned entitlements correctly
- persistence survives crash/restart/reinstall scenarios where backend restore is required

## 16. Ads

Verify both code and real-device/internal-test behavior.

Require:

- production AdMob App ID and ad unit mapping are correct for the shipped package
- debug builds use official test ad IDs
- no accidental production impressions during development
- rewarded currency/help is granted only from the earned-reward callback
- failed/cancelled reward ads grant nothing
- interstitials occur only at natural breaks
- interstitial frequency cap/cooldown is respected
- no ad blocks gameplay controls
- consent status gates ad loading appropriately
- privacy options remain accessible
- no-ad entitlement suppresses eligible ads
- app name changes do not cause assumptions: verify using package/app IDs and linked AdMob/Play records

Keep the current repository’s intended 180-second interstitial cooldown/session cap unless product requirements deliberately change and tests are updated.

## 17. Play Billing / purchases

Verify:

- billing client connection/reconnect
- current product IDs
- localized pricing display
- purchase success
- cancel
- pending
- error
- duplicate callback
- consume for consumables
- acknowledge where required
- restore
- reinstall
- second-device restore
- refund/revocation handling where supported
- non-consumable duplicate-grant prevention
- starter-pack/one-time grant idempotency
- server-side verification in production
- raw purchase tokens are not persisted unnecessarily

Production purchase verification must fail closed if the live verification backend is unavailable.

# Privacy, security and backend

## 18. Security pass

Search for:

- committed secrets
- API keys that should not be public
- unsafe service credentials
- hard-coded privileged backend tokens
- insecure HTTP production endpoints
- insufficient server-side purchase verification
- replay/double-grant vulnerabilities
- unsafe file/save parsing
- path traversal or arbitrary file access
- debug/development endpoints exposed in release
- overly verbose production logs containing identifiers/tokens
- dependency/plugin risks relevant to shipped code

Run available security tooling before completion.

## 19. Save integrity

Test:

- normal save/load
- corrupted save recovery
- backup restore
- temporary-file/atomic replacement
- unexpected/missing fields
- old-version migration
- invalid balances/progress sanitization
- interrupted write
- reset progress
- entitlement preservation
- app kill during state transition

No normal user action should permanently corrupt progression.

## 20. Privacy and consent

Verify shipped SDK behavior matches:

- privacy policy
- Play Data Safety declaration
- advertising ID declaration
- consent implementation
- analytics behavior
- purchase/backend data collection

Do not describe data practices more narrowly than the actual SDKs collect.

# Performance and device quality

## 21. Performance

Measure on realistic mobile conditions, not only desktop headless runs.

Audit:

- startup/import time
- scene transitions
- steady gameplay FPS
- 1% low / frame spikes when available
- memory growth across repeated game transitions
- 3D rebuild cost
- draw calls
- shader compilation stutter
- particles/lights/transparency
- idle CPU/GPU work
- battery-unfriendly continuous updates
- large textures/audio assets
- unnecessary node/process loops

The game should remain responsive during animation and after long sessions. Prefer profiling evidence over speculative optimization.

## 22. Robustness / lifecycle

Test:

- rapid navigation
- repeated open/close modals
- pause/resume
- Android background/foreground
- interrupted animations
- network loss/restore
- ad return
- billing return
- orientation handling according to portrait lock
- low-memory/reload behavior where practical
- repeated new game/restart
- long gameplay session
- fresh install and upgraded install

# CI, Android and Google Play

## 23. CI

All required workflows for the target commit must be green, including where configured:

- Godot CI
- visual audit
- Block campaign review
- monetization readiness
- Android production release gates

Inspect artifacts instead of treating a green shell command as proof of rendered quality.

## 24. Android export

Verify:

- package ID
- versionName/versionCode
- target/min SDK
- architecture
- portrait/immersive settings
- Android manifest permissions
- advertising ID declaration if used
- AdMob/UMP/billing plugin packaging
- debug APK smoke install
- production AAB export
- release signing path
- no debug flags/providers in production

Use a debug APK only for testing. Production uses a release AAB signed with the owner-controlled upload key.

## 25. Google Play readiness

Before calling the repository release-ready, reconcile the exact current Play requirements with fresh official documentation.

Verify/review:

- Play App Signing
- upload key
- unique/higher version code after first accepted upload
- app category
- target audience
- content rating/IARC
- Contains ads
- Data Safety
- advertising ID
- privacy-policy URL
- developer website
- `app-ads.txt` at the developer website hostname root
- AdMob linkage/readiness
- store listing
- 512×512 app icon
- 1024×500 feature graphic
- real phone screenshots
- closed/internal testing requirements applicable to the developer account
- production access requirements
- billing products/prices

Never alter a truthful declaration merely to bypass Play review.

# Visual evidence protocol

## 26. Rendered review

Use the existing rendered visual-audit path and add temporary targeted captures only when needed.

For each major screen/game capture enough evidence to inspect:

- compact portrait
- standard portrait
- tall portrait
- overlays/modals
- gameplay action state
- end-of-level state

Look for:

- clipping
- overlap
- tiny text
- tiny buttons
- inconsistent margins
- misaligned icons
- weak contrast
- stale/duplicate sprites
- z-order mistakes
- incorrect shadows
- stretched art
- bad safe-area placement
- transition remnants
- low-quality placeholder imagery

Do not approve screenshots only because they contain all controls. Judge composition and premium finish.

# Change implementation protocol

## 27. Fix in priority order

1. P0 correctness/security/data/payment/build issues
2. P1 gameplay/layout/accessibility/performance defects
3. progression/daily/retention completeness
4. monetization correctness
5. UI hierarchy and screen-fit
6. 3D/material/lighting/background polish
7. motion/audio/haptics
8. maintainability/dead code
9. release documentation and final packaging

For every bug fix:

- reproduce
- identify root cause
- implement focused fix
- add/update a short precise regression test when valuable
- run targeted validation
- inspect collateral effects
- then run broader suite

## 28. Dead/incomplete code

Search for:

- TODO/FIXME/HACK
- unreachable code
- unused scenes/scripts/assets
- duplicate managers
- placeholder data
- debug toggles
- abandoned feature flags
- stubs returning constants
- unconnected UI buttons
- signals with no valid receiver
- handlers never called
- hardcoded development values
- unused exports/resources

Do not remove code solely because static search reports it unused; confirm Godot scene/resource/signal references first.

# Definition of Done

UNJAM is code-complete only when all of the following are true for the exact final commit:

- project imports without unexpected errors
- app boots successfully
- all required automated validators pass
- no known P0 or P1 defects remain
- all three games are fully playable
- representative 10,000-level progression checks pass for all three games
- daily challenges are reachable and function correctly
- every user-visible screen has been reviewed
- compact/normal/tall portrait layouts fit correctly
- text and controls are comfortably readable/tappable
- no known overlaps, clipping, duplicate pieces, stale rendering or transition remnants remain
- home and game-selection screens meet the premium product bar
- game visuals/materials/lighting/backgrounds are coherent and polished
- motion is smooth and state-safe
- audio is commercially usable, balanced and non-irritating
- no major FPS/memory/idle-cost regression remains
- save corruption/recovery paths pass
- monetization tests pass
- production ads use correct configuration and safe consent/reward rules
- purchase flow is secure and server-verified in production
- privacy/security pass has no unresolved release-blocking finding
- debug APK can be generated and smoke-tested
- production AAB export gate passes when owner secrets/services are configured
- required CI is green
- final diff is reviewed
- release checklist accurately reflects the current state
- remaining owner-only/account-side tasks are explicitly listed, not hidden inside “done”

## Manual-owner tasks are not code defects

Examples that may remain after repository completion:

- creating/updating the Play Console listing
- adding protected signing secrets
- creating billing products and prices
- linking Play and AdMob account-side records
- publishing `app-ads.txt` at the developer website hostname root
- completing Play declarations
- providing screenshots/assets that require final device capture
- conducting required closed/internal tests with real accounts/devices
- enabling or approving cloud APIs/billing/account verification

When these are the only blockers, state: “Repository/code side is complete; release is awaiting owner/account actions,” then list each action precisely.

# Final review and merge

Before merging:

1. fetch latest `main`
2. verify branch is not unintentionally behind
3. inspect all changed files and diff stats
4. rerun targeted tests for touched areas
5. rerun the full required suite
6. inspect latest rendered visual evidence
7. check security and release configuration
8. confirm no secrets or generated junk are included
9. confirm README/release checklist remain accurate
10. merge only when the branch is reviewable and gates pass

Do not merge known broken work merely because most tests pass.

# Completion report

At the end, report:

- baseline problems found
- fixes implemented, grouped by gameplay/UI/UX/performance/audio/monetization/security/release
- important files changed
- tests and workflows run
- visual/device states reviewed
- performance findings
- monetization/backend status
- security/privacy status
- build artifacts produced
- final branch/commit/PR/merge status
- remaining owner-only actions
- any limitation that could not be independently verified

Keep the report factual. Distinguish measured evidence from judgment.

# Quality principle

The standard is not “looks okay for an indie prototype.” The target is a coherent, polished mobile puzzle product that can sit beside well-produced casual games without obvious developer UI, tiny controls, unfinished backgrounds, rough motion, fragile gameplay, intrusive monetization, or release-process gaps.
