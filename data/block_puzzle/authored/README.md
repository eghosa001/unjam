# Block Puzzle authored campaign

Block Puzzle levels 1-10,000 are explicitly authored in 20 chapter files of 500 recipes each.

Every recipe freezes:
- retention role and milestone
- target difficulty and first-attempt success band
- objective family and introduction age
- piece tier and planning horizon
- starting board occupancy
- line/score targets and par
- move-limit state and exact move limit
- boss archetype
- shape/tray bias used by the constructive generator
- deterministic authored seed
- a human-readable design intent

Runtime loads only the active 500-level chapter through `BlockPuzzleAuthoredCatalog`.
`BlockPuzzleProgression` uses the authored recipe as the source of truth. The older
formula logic remains only as a fallback if an authored chapter cannot be loaded.

Boards and trays remain deterministic and constructively solvable from each authored
recipe and seed, so one level can be tuned without changing neighboring levels.

Campaign retention rules:
- no more than two consecutive challenge/stretch/peak roles
- immediate recovery after boss/major milestone pressure
- no move limits on ordinary learn/practice/recovery/confidence levels
- sawtooth difficulty instead of a monotonic grind
- late worlds rotate multiple previously learned objective families
- multiple shape-bias families per world
- unique deterministic seeds for all 10,000 levels
- a fixed World 20 / Level 10,000 grandmaster finale
