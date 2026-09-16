extends "res://scripts/ui/ux_shell_premium.gd"

const VIBRANT_REFERENCE_TARGET := "approved-colorful-reference"

func _main() -> Node:
	var parent := get_parent()
	if parent != null:
		return parent
	return super._main()

func _build_shell() -> void:
	super._build_shell()
	_compact_shell()
	_vibrant_tutorial_shell()

func _after_shell_sync() -> void:
	_compact_shell()

func show_tutorial(game_id: String = "rescue_rush") -> void:
	super.show_tutorial(game_id)
	_vibrant_tutorial_shell(game_id)

func _compact_shell() -> void:
	if help_button != null:
		help_button.text = "?"
		help_button.custom_minimum_size = Vector2(72, 72)
		help_button.size = Vector2(72, 72)
		var viewport_size := get_viewport().get_visible_rect().size
		var desired := Vector2(24, maxf(24.0, viewport_size.y - 96.0))
		var footer: Control = _gameplay_footer()
		if footer != null and footer.visible and footer.is_visible_in_tree():
			var proposed := Rect2(desired, Vector2(72, 72))
			var footer_rect: Rect2 = footer.get_global_rect()
			if proposed.intersects(footer_rect):
				desired.y = maxf(24.0, footer_rect.position.y - 84.0)
		help_button.position = desired
		help_button.add_theme_font_size_override("font_size", 28)
		help_button.tooltip_text = "How to play"
	if theme_button != null:
		theme_button.visible = false

func _vibrant_tutorial_shell(game_id: String = "") -> void:
	if tutorial_panel == null or tutorial_layer == null:
		return
	var id := game_id if not game_id.is_empty() else _current_game()
	if id not in PremiumDesignSystem.GAME_ACCENTS:
		id = "rescue_rush"
	var gradient: Array = PremiumDesignSystem.game_gradient(id)
	var primary: Color = gradient[0]
	var secondary: Color = gradient[1]
	var dim := tutorial_layer.get_node_or_null("TutorialDim") as ColorRect
	if dim != null:
		dim.color = Color(0.05, 0.15, 0.28, 0.34)
	tutorial_panel.position = Vector2(-450, -580)
	tutorial_panel.custom_minimum_size = Vector2(900, 1160)
	tutorial_panel.add_theme_stylebox_override("panel", PremiumDesignSystem.box(Color("fffaf0"), 40, Color(primary.lightened(0.18), 0.96), 4, 18, false))
	if tutorial_title != null:
		tutorial_title.add_theme_font_size_override("font_size", 44)
		tutorial_title.add_theme_color_override("font_color", secondary.darkened(0.34))
		tutorial_title.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.65))
		tutorial_title.add_theme_constant_override("shadow_offset_y", 2)
	if tutorial_body != null:
		tutorial_body.add_theme_font_size_override("font_size", 29)
		tutorial_body.add_theme_color_override("font_color", Color("36516d"))
	var close := tutorial_panel.find_child("TutorialClose", true, false) as Button
	if close != null:
		PremiumDesignSystem.apply_button(close, true, primary, "primary", 26)
	for child in tutorial_panel.find_children("*", "Button", true, false):
		var button := child as Button
		if button != null and button != close:
			var color := primary
			if button.text.contains("WATER"):
				color = PremiumDesignSystem.accent_for_game("water_sort")
			elif button.text.contains("BLOCK"):
				color = PremiumDesignSystem.accent_for_game("block_puzzle")
			PremiumDesignSystem.apply_button(button, true, color, "secondary", 22)

func _gameplay_footer() -> Control:
	var main := _main()
	if main == null:
		return null
	var game: Node = main.get("active_game") as Node
	if game == null or not is_instance_valid(game):
		game = main.get_node_or_null("ActiveGame")
	if game == null:
		return null
	return _find_named_control(game, ["CompactGameActions", "CompactProgressStrip"])

func _find_named_control(node: Node, names: Array[String]) -> Control:
	if node is Control and String(node.name) in names:
		return node as Control
	for child in node.get_children():
		var found: Control = _find_named_control(child, names)
		if found != null:
			return found
	return null
