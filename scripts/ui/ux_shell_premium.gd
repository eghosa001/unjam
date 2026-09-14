extends "res://scripts/ui/ux_shell.gd"

func _is_custom_surface(node: Node) -> bool:
	var cursor: Node = node
	while cursor != null:
		if cursor.name in ["PremiumHome", "PremiumLive", "ActiveGame"]:
			return true
		var script := cursor.get_script() as Script
		if script != null:
			var path := String(script.resource_path)
			if path.begins_with("res://scripts/game/") or path.ends_with("premium_home_overhaul.gd") or path.ends_with("premium_live_hub.gd"):
				return true
		cursor = cursor.get_parent()
	return false

func _soften_control(node: Node) -> void:
	if not is_instance_valid(node):
		return
	# Gameplay and premium launcher surfaces have deliberately authored art direction.
	# Do not let the generic shell flatten their cards, controls or typography.
	if _is_custom_surface(node):
		return
	if node is Button and not node is WaterTubeButton and not node is BlockPieceButton and not node is PremiumPieceButton and not node is BlockCellButton:
		var b := node as Button
		var strong := b.name in ["TutorialClose"]
		if strong:
			b.add_theme_stylebox_override("normal", _box(ACCENT, 22, ACCENT.lightened(0.15), 2))
			b.add_theme_stylebox_override("hover", _box(ACCENT.lightened(0.08), 22, Color.WHITE, 2))
			b.add_theme_stylebox_override("pressed", _box(ACCENT.darkened(0.10), 22, Color.WHITE, 2))
			b.add_theme_color_override("font_color", Color.WHITE)
		else:
			b.add_theme_stylebox_override("normal", _box(_surface_2(), 22, _border(), 2))
			b.add_theme_stylebox_override("hover", _box(_surface(), 22, ACCENT, 3))
			b.add_theme_stylebox_override("pressed", _box(ACCENT.darkened(0.08) if theme_mode == "dark" else Color("dfe4ff"), 22, ACCENT, 3))
			b.add_theme_stylebox_override("disabled", _box(_disabled(), 22, _border(), 1))
			b.add_theme_color_override("font_color", _ink())
			b.add_theme_color_override("font_hover_color", _ink())
			b.add_theme_color_override("font_pressed_color", _ink())
			b.add_theme_color_override("font_disabled_color", _muted())
	elif node is PanelContainer:
		var p := node as PanelContainer
		if p.name != "TutorialPanel" and not p.has_theme_stylebox_override("panel"):
			p.add_theme_stylebox_override("panel", _box(Color(_surface(), 0.96), 28, _border(), 2))
	elif node is Label:
		var l := node as Label
		if not l.has_theme_color_override("font_color"):
			l.add_theme_color_override("font_color", _ink())
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.0))
	for child in node.get_children():
		_soften_control(child)