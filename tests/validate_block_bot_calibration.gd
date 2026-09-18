extends SceneTree

const Progression = preload("res://scripts/core/block_puzzle_progression.gd")
const LevelPack = preload("res://scripts/core/block_puzzle_level_pack.gd")
const Auditor = preload("res://scripts/core/block_puzzle_campaign_auditor.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var levels := [1, 5, 10, 25, 100, 500, 501, 1000, 2500, 5000, 7500, 9000, 9500, 9999, 10000]
	var signatures := {}
	var early_total := 0
	var early_count := 0
	var late_total := 0
	var late_count := 0
	for level in levels:
		var profile := _profile(level)
		var plan := LevelPack.plan_for_level(level, profile)
		var report := Auditor.audit_plan(profile, plan)
		if not bool(report.get("valid", false)):
			return _fail("Block bot audit invalid at level %d" % level)
		var signature := String(report.get("signature", ""))
		if signature.is_empty() or signatures.has(signature):
			return _fail("Block bot audit found a sampled duplicate at level %d" % level)
		signatures[signature] = level
		var calibrated := int(report.get("calibrated_difficulty", 0))
		if level <= 500:
			early_total += calibrated
			early_count += 1
		if level >= 7500:
			late_total += calibrated
			late_count += 1
	if late_count <= 0 or early_count <= 0:
		return _fail("Calibration sample bands are incomplete")
	if float(late_total) / float(late_count) <= float(early_total) / float(early_count):
		return _fail("Late-game multi-bot difficulty did not exceed the early-game sample")
	print("BLOCK_BOT_CALIBRATION_OK")
	quit(0)

func _profile(level: int) -> Dictionary:
	var p := Progression.profile(level)
	if level <= 10:
		var scores := [100, 130, 165, 190, 220, 255, 285, 315, 350, 390]
		var lines := [2, 2, 3, 3, 3, 4, 4, 4, 5, 5]
		p["target_score"] = scores[level - 1]
		p["target_lines"] = lines[level - 1]
	return p

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
