extends "res://scripts/ui/premium_home_casual.gd"

# Keep the premium mascot hero visually bounded on tall phones while allowing
# its surrounding stage slot to absorb surplus vertical space. This preserves
# the full-screen composition without turning the hero card into a giant empty
# panel above PLAY.
func _make_hero(parent: VBoxContainer) -> void:
	super._make_hero(parent)
	var hero := parent.get_node_or_null("HomeHero3D") as Control
	if hero == null:
		return
	var viewport_size := get_viewport_rect().size
	var bounded_height := hero.custom_minimum_size.y
	if viewport_size.y >= 1400.0:
		bounded_height = clampf(viewport_size.y * 0.27, 500.0, 540.0)

	var hero_index := hero.get_index()
	parent.remove_child(hero)
	var stage_slot := CenterContainer.new()
	stage_slot.name = "HomeHeroStageSlot"
	stage_slot.custom_minimum_size = Vector2(0, bounded_height)
	stage_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(stage_slot)
	parent.move_child(stage_slot, hero_index)

	hero.custom_minimum_size = Vector2(0, bounded_height)
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stage_slot.add_child(hero)

	var mascot := hero.find_child("HomeMascot3D", true, false) as Control
	if mascot != null:
		mascot.custom_minimum_size.y = maxf(190.0, bounded_height - 40.0)

# Home keeps the large PLAY route for players who want the three-game selector,
# while each game card is itself a direct shortcut to that game's level browser.
func _make_game_strip(parent: VBoxContainer) -> void:
	var strip := HBoxContainer.new()
	strip.name = "HomeGameStrip"
	var viewport_size := get_viewport_rect().size
	var short_phone := viewport_size.y < 1100.0
	strip.custom_minimum_size = Vector2(0, 74 if short_phone else (118 if viewport_size.y >= 1400.0 else 96))
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 10)
	parent.add_child(strip)
	var games := [
		["rescue_rush", "RESCUE\nRUSH", Unjam3DTheme.GREEN],
		["water_sort", "WATER\nSORT", Unjam3DTheme.WATER],
		["block_puzzle", "BLOCK\nPUZZLE", Unjam3DTheme.PURPLE]
	]
	for entry in games:
		var game_id := String(entry[0])
		var accent: Color = entry[2]
		var button := Button.new()
		button.name = "HomeDirect_%s" % game_id
		button.text = String(entry[1])
		button.custom_minimum_size = Vector2(0, 66 if short_phone else 90)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 15 if viewport_size.x < 600.0 else 18)
		button.tooltip_text = "Open %s levels" % MultiGameManager.display_name(game_id)
		var button_accent := accent.darkened(0.18) if _theme_mode() == "dark" else accent
		Unjam3DTheme.gloss_button(button, button_accent, true, 24)
		button.pressed.connect(_open_game_levels.bind(game_id))
		strip.add_child(button)

func _open_game_levels(game_id: String) -> void:
	var main := get_parent()
	if main == null or not main.has_method("open_game_campaign"):
		return
	FeedbackManager.tap()
	main.call("open_game_campaign", game_id)
