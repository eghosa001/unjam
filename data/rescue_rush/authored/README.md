# Rescue Rush authored campaign

Rescue Rush levels 1-10,000 are explicitly authored in 20 chapter files of 500 recipes each.

Each recipe freezes the level's:
- retention role and milestone
- target difficulty and first-attempt success band
- board size, piece density, dependency target and frontier target
- objective and mechanic combination
- mistake allowance, action budget and required chain
- exit direction, rescue placement variant and deterministic generation seed
- layout archetype and design intent

Runtime loads only the active 500-level chapter through `RescueRushAuthoredCatalog`.
`RescueRushProgression` uses these recipes as the source of truth. Its older formula
logic remains only as a fallback if an authored chapter cannot be loaded.

The actual board remains deterministic from the authored recipe and seed, so individual
levels can be tuned by editing one JSON row without changing neighboring levels.

Validation:
- `validate_rescue_authored_catalog_10000.gd` checks all 10,000 recipes for pacing,
  unlocks, objective prerequisites, milestone recovery, seed uniqueness and chapter curve.
- `validate_rescue_progression_10000.gd` solver-checks representative authored boards.
- `validate_campaign.gd` is the exhaustive 10,000-board structure/solvability gate.
