extends "res://scripts/ui/ux_shell_premium.gd"

func _main() -> Node:
	var parent := get_parent()
	if parent != null:
		return parent
	return super._main()

func _build_shell() -> void:
	super._build_shell()
	_compact_shell()
	_restyle_3d_shell()

func _after_shell_sync() -> void:
	_compact_shell()
	_restyle_3d_shell()

func _apply_theme() -> void:
	super._apply_theme()
	_restyle_3d_shell()

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

func _restyle_3d_shell() -> void:
	if help_button != null:
		Unjam3DTheme.gloss_button(help_button, Unjam3DTheme.WATER_DARK, true, 28)
	if tutorial_layer == null or tutorial_panel == null:
		return
	var dim := tutorial_layer.get_node_or_null("TutorialDim") as ColorRect
	if dim != null:
		dim.color = Color(0.01, 0.18, 0.34, 0.72)
	tutorial_panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("f8fdff"), 40, Color("66d4ff"), 4, 20))
	if tutorial_title != null:
		Unjam3DTheme.label_3d(tutorial_title, Unjam3DTheme.NAVY, Color.WHITE, 3)
	if tutorial_body != null:
		Unjam3DTheme.label_3d(tutorial_body, Color("315878"), Color.WHITE, 2)
	_restyle_tutorial_children(tutorial_panel)

func _restyle_tutorial_children(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			var button := child as Button
			var strong := button.name == "TutorialClose"
			Unjam3DTheme.gloss_button(button, Unjam3DTheme.GREEN if strong else Unjam3DTheme.WATER_DARK, strong, 24)
		elif child is Label and child != tutorial_title and child != tutorial_body:
			var label := child as Label
			Unjam3DTheme.label_3d(label, Unjam3DTheme.NAVY, Color.WHITE, 2)
		_restyle_tutorial_children(child)

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
