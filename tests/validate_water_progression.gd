extends SceneTree

const Progression = preload("res://scripts/core/water_sort_progression.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var checkpoints := [1, 2, 3, 5, 8, 10, 25, 50, 100, 500, 1000, 2500, 5000, 7500, 9000, 9500, 10000]
	for level in checkpoints:
		var first := Progression.profile(level)
		var second := Progression.profile(level)
		if first != second:
			return _fail("Profile is not deterministic at level %d" % level)
		if int(first.colors) < 3 or int(first.colors) > 12:
			return _fail("Color count outside 3..12 at level %d" % level)
		if int(first.empty_bottles) < 1 or int(first.empty_bottles) > 2:
			return _fail("Empty bottle count outside 1..2 at level %d" % level)
		if int(first.world) < 1 or int(first.world) > 20:
			return _fail("World outside 1..20 at level %d" % level)
		if bool(first.hidden_information):
			return _fail("Main campaign unexpectedly enables hidden information at level %d" % level)

	var first_level := Progression.profile(1)
	if int(first_level.colors) != 3:
		return _fail("Level 1 must start at 3 colors")
	var final_level := Progression.profile(10000)
	if int(final_level.colors) != 12 or int(final_level.empty_bottles) != 1:
		return _fail("Level 10000 must use 12 colors and one strategic empty bottle")
	if String(final_level.milestone) != "finale" or int(final_level.world) != 20:
		return _fail("Level 10000 is not the world-20 finale")
	if int(Progression.profile(5000).difficulty_floor) <= int(Progression.profile(1000).difficulty_floor):
		return _fail("Difficulty floor does not rise through the campaign")
	if int(final_level.difficulty_floor) <= int(Progression.profile(5000).difficulty_floor):
		return _fail("Endgame difficulty floor does not keep rising")

	var late_one_empty := 0
	for level in range(9001, 10001):
		if int(Progression.profile(level).empty_bottles) == 1:
			late_one_empty += 1
	if late_one_empty < 200 or late_one_empty > 450:
		return _fail("Late-game one-empty mix is outside the intended 20-45%% range: %d/1000" % late_one_empty)

	if String(Progression.milestone_kind(10)) != "challenge":
		return _fail("Level 10 challenge milestone missing")
	if String(Progression.milestone_kind(25)) != "hard":
		return _fail("Level 25 hard milestone missing")
	if String(Progression.milestone_kind(50)) != "mini_boss":
		return _fail("Level 50 mini-boss missing")
	if String(Progression.milestone_kind(100)) != "boss":
		return _fail("Level 100 boss missing")
	if String(Progression.milestone_kind(500)) != "world_finale":
		return _fail("Level 500 world finale missing")
	if String(Progression.milestone_kind(1000)) != "mastery":
		return _fail("Level 1000 mastery milestone missing")

	var canonical_a := [[0, 1, 2, 0], [1, 2, 0, 1], [], []]
	var canonical_b := [[7, 9, 4, 7], [9, 4, 7, 9], [], []]
	if Progression.canonical_signature(canonical_a) != Progression.canonical_signature(canonical_b):
		return _fail("Color-renamed duplicate boards are not canonicalized")

	var scores: Array[int] = []
	for level in range(1001, 1101):
		scores.append(int(Progression.profile(level).target_difficulty))
	var rising_only := true
	for i in range(1, scores.size()):
		if scores[i] < scores[i - 1]:
			rising_only = false
			break
	if rising_only:
		return _fail("Difficulty curve lost its sawtooth relief pattern")

	print("WATER_PROGRESSION_OK: deterministic 20x500 campaign, 12-color cap, rising floor, milestones, strategic empties, canonical duplicate guard.")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
