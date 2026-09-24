extends SceneTree

const Solver = preload("res://scripts/core/puzzle_solver.gd")
const Generator = preload("res://scripts/core/campaign_generator.gd")

const RETIRED_UI_PATCHES := [
	"res://scripts/ui/global_finish_polish.gd",
	"res://scripts/ui/home_cinematic_polish.gd",
	"res://scripts/ui/home_ux_patch.gd",
	"res://scripts/ui/secondary_surface_fill.gd"
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	ProjectSettings.set_setting("monetization/test_mode", true)
	var errors: Array[String] = []
	var project_file := FileAccess.open("res://project.godot", FileAccess.READ)
	if project_file == null:
		errors.append("project.godot could not be read")
	else:
		var project_text := project_file.get_as_text()
		if project_text.contains("res://addons/stagehand/plugin.cfg"):
			errors.append("Missing Stagehand editor plugin is still enabled in production project config")
	for retired_path in RETIRED_UI_PATCHES:
		if FileAccess.file_exists(retired_path):
			errors.append("Retired UI patch layer still ships: %s" % retired_path)
	var save_manager := get_root().get_node_or_null("SaveManager")
	var daily := get_root().get_node_or_null("DailyChallenge")
	var ads := get_root().get_node_or_null("AdManager")
	if save_manager == null or daily == null or ads == null:
		errors.append("Required production autoload missing")
		_finish(errors)
		return
	var original_processed_tokens: Array = (save_manager.data.get("processed_purchase_tokens", []) as Array).duplicate(true)
	var original_claim_ids: Dictionary = (save_manager.data.get("purchase_claim_ids", {}) as Dictionary).duplicate(true)
	for level_number in [11, 25, 100, 101, 999, 2500, 5000, 7500, 9999, 10000]:
		var level: Dictionary = Generator.generate(level_number)
		if not Solver.has_solution(level, 6000):
			errors.append("Representative level %d is not solvable" % level_number)
	var daily_level: Dictionary = daily.build_today()
	if daily_level.is_empty() or not Solver.has_solution(daily_level, 6000):
		errors.append("Daily challenge is not solvable")
	save_manager.reset_progress()
	var first: Dictionary = save_manager.complete_level(1, 3, "chick", 75)
	var second: Dictionary = save_manager.complete_level(1, 3, "chick", 75)
	if int(save_manager.data.total_levels_completed) != 1: errors.append("Replay incorrectly increments unique completion count")
	if int(save_manager.data.perfect_clears) != 1: errors.append("Replay incorrectly increments unique perfect count")
	if int(first.get("base_coins", -1)) != 75: errors.append("First-clear reward accounting is incorrect")
	if int(second.get("base_coins", -1)) != 0: errors.append("Replay reward duplication protection failed")
	if int(save_manager.data.get("save_version", 0)) < 11: errors.append("Robust save version 11 purchase-claim migration is missing")
	var legacy_token := "qa-legacy-raw-token-at-save-boundary"
	var fingerprint := legacy_token.sha256_text()
	save_manager.data.processed_purchase_tokens = [legacy_token, fingerprint.to_upper()]
	save_manager.call("_sanitize")
	var sanitized_tokens: Array = save_manager.data.get("processed_purchase_tokens", [])
	var valid_claim_key := "qa-claim-token".sha256_text()
	save_manager.data.purchase_claim_ids = {}
	save_manager.data.purchase_claim_ids[valid_claim_key] = "qa-claim-id-1234"
	save_manager.data.purchase_claim_ids["not-a-hash"] = "bad"
	save_manager.call("_sanitize")
	var sanitized_claims: Dictionary = save_manager.data.get("purchase_claim_ids", {})
	if String(sanitized_claims.get(valid_claim_key, "")) != "qa-claim-id-1234": errors.append("Valid purchase claim id was removed by save sanitization")
	if sanitized_claims.has("not-a-hash"): errors.append("Invalid purchase claim fingerprint survived save sanitization")
	if legacy_token in sanitized_tokens: errors.append("Raw Play purchase token survived save sanitization")
	if sanitized_tokens.count(fingerprint) != 1: errors.append("Purchase-token sanitization did not deduplicate to one SHA-256 fingerprint")
	save_manager.data.processed_purchase_tokens = original_processed_tokens
	save_manager.data.purchase_claim_ids = original_claim_ids
	save_manager.save()
	ads.completed_since_interstitial = 0
	ads.set_ads_enabled(true)
	for i in range(ads.interstitial_interval): ads.note_level_completed()
	if not ads.should_show_interstitial(): errors.append("Interstitial pacing does not reach ready state")
	save_manager.reset_progress()
	_finish(errors)

func _finish(errors: Array[String]) -> void:
	if not errors.is_empty():
		for error in errors: printerr(error)
		printerr("Production robustness validation failed with %d issue(s)." % errors.size())
		quit(1)
		return
	print("Production robustness validated: solvability, daily challenge, save accounting, token privacy, ad pacing and production cleanup.")
	quit(0)
