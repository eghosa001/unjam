extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var home := FileAccess.get_file_as_string("res://scripts/ui/premium_home_direct_levels.gd")
	var selector := FileAccess.get_file_as_string("res://scripts/ui/premium_live_hub_3d.gd")
	var main := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")

	var hero_preview := _function_block(home, "func _add_hero_preview(canvas: Control, game_id: String) -> void:")
	_check("rounded_gradient3" not in hero_preview, "Home hero preview still uses glossy gradient material", failures)
	_check("RefCanvas.solid_box(stage_fill" in hero_preview, "Home hero preview lost flat containment styling", failures)

	var selector_card := _function_block(selector, "func _add_game_card(canvas: Control, game_id: String, rect: Rect2, accent: Color, highlight: Color, title: String, subtitle: String) -> void:")
	_check("SelectorAccentRail_" in selector_card, "Choose Game cards are missing the flat accent rail", failures)
	var selector_nav := _function_block(selector, "func _add_bottom_nav(canvas: Control) -> void:")
	_check("rounded_gradient3" not in selector_nav, "Choose Game navigation still uses glossy gradient material", failures)
	_check('Color("#252629")' in selector_nav and 'Color("#f0ede6")' in selector_nav, "Choose Game navigation is not using the refined neutral palette", failures)

	var daily_state := _function_block(main, "func _daily_ui_state(game_id: String, accent: Color) -> Dictionary:")
	_check('"fill":accent' in daily_state, "Daily PLAY buttons are not using each game's accent", failures)
	var daily_card := _function_block(main, "func _figma_daily_card(canvas: Control, game_id: String, y: float, collection_bonus: int) -> void:")
	_check("rounded_gradient3" not in daily_card, "Daily accent rail still uses glossy gradient material", failures)
	_check('Color("#27282b")' in daily_card and 'Color("#f5f2ec")' in daily_card, "Daily cards are not using the neutral surface palette", failures)

	var bottom_nav := _function_block(main, "func _figma_bottom_nav(canvas: Control, active: String, dark_mode: bool = false) -> void:")
	_check("rounded_gradient3" not in bottom_nav, "Shared bottom navigation still uses glossy gradient material", failures)
	_check("StdNavActiveShine_" in bottom_nav and "Rect2(float(hit_x[key])+24.0,765,24,2)" in bottom_nav, "Bottom navigation active marker is not restrained", failures)

	var settings_card := _function_block(main, "func _figma_settings_card(canvas: Control, name_value: String, rect: Rect2, fill: Color, border: Color, dark_mode: bool) -> PanelContainer:")
	_check("modulate.a = 0.70" not in settings_card, "Light Settings cards remain washed out", failures)

	if failures.is_empty():
		print("FLAT_POLISH_V8_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _function_block(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		return source.substr(start)
	return source.substr(start, next - start)

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
