extends "res://scripts/ui/premium_surface_manager.gd"

# App-wide bridge for the new bright 3D visual language. Legacy gameplay
# mechanics stay untouched while levels, settings and collection surfaces are
# reskinned through one lightweight pass.

func _configure_background(root: Node, game_id: String, _dark: bool, accent: Color) -> void:
	if root is Control:
		var control := root as Control
		var bg := control.get_node_or_null("Unjam3DSurfaceBackdrop") as Unjam3DBackdrop
		if bg == null:
			bg = Unjam3DBackdrop.new()
			bg.name = "Unjam3DSurfaceBackdrop"
			bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			bg.z_index = -100
			control.add_child(bg)
			control.move_child(bg, 0)
		bg.configure(Unjam3DTheme.game_accent(game_id))
	_hide_legacy_backdrops(root)
	PremiumVisuals.set_accent(accent)

func _hide_legacy_backdrops(node: Node) -> void:
	for child in node.get_children():
		var path := _script_path(child)
		if path.ends_with("premium_backdrop.gd"):
			if child is CanvasItem:
				(child as CanvasItem).visible = false
			continue
		_hide_legacy_backdrops(child)

func _polish_tree(node: Node, surface: String, _dark: bool, accent: Color) -> void:
	if not is_instance_valid(node):
		return
	if node is Button and not _is_gameplay_widget(node):
		var button := node as Button
		button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 82.0)
		button.add_theme_font_size_override("font_size", maxi(21, button.get_theme_font_size("font_size")))
		var role := _role_for_surface_button(button, surface)
		var button_accent := _button_accent(role, accent)
		Unjam3DTheme.gloss_button(button, button_accent, role in ["primary", "reward", "success"], 24 if not _looks_like_level_button(button, surface) else 20)
	elif node is PanelContainer:
		var panel := node as PanelContainer
		var emphasis := _panel_emphasis(panel, surface)
		var fill := Color(0.96, 0.995, 1.0, 0.95) if not emphasis else Color(0.90, 0.98, 1.0, 0.97)
		panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(fill, 30 if emphasis else 25, Color(accent, 0.66) if emphasis else Color("9adfff"), 3 if emphasis else 2, 11 if emphasis else 6))
	elif node is Label:
		var label := node as Label
		var font_size := label.get_theme_font_size("font_size")
		if font_size > 0:
			label.add_theme_font_size_override("font_size", font_size + (4 if font_size >= 28 else 2))
		var text := label.text.strip_edges().to_upper()
		var color := Unjam3DTheme.NAVY
		if "COIN" in text or "★" in text or "PRESTIGE" in text:
			color = Color("d88700")
		elif font_size >= 28 or text.begins_with("WORLD "):
			color = Unjam3DTheme.game_dark(_game_id_from_accent(accent))
		Unjam3DTheme.label_3d(label, color, Color(1, 1, 1, 0.85), 2 if font_size < 24 else 3)
	elif node is ProgressBar:
		var progress := node as ProgressBar
		progress.add_theme_stylebox_override("background", Unjam3DTheme.panel_3d(Color("d7efff"), 12, Color("84d5ff"), 2, 2))
		progress.add_theme_stylebox_override("fill", Unjam3DTheme.panel_3d(accent, 12, accent.lightened(0.30), 2, 3))
	for child in node.get_children():
		if child.name == "Unjam3DSurfaceBackdrop":
			continue
		_polish_tree(child, surface, false, accent)

func _button_accent(role: String, accent: Color) -> Color:
	match role:
		"reward": return Unjam3DTheme.ORANGE
		"success": return Unjam3DTheme.GREEN
		"danger": return Unjam3DTheme.RED
		"primary": return accent
		_: return Unjam3DTheme.WATER_DARK

func _game_id_from_accent(accent: Color) -> String:
	if accent.is_equal_approx(PremiumDesignSystem.accent_for_game("water_sort")):
		return "water_sort"
	if accent.is_equal_approx(PremiumDesignSystem.accent_for_game("block_puzzle")):
		return "block_puzzle"
	return "rescue_rush"

func _add_surface_chrome(content: Control, surface: String, game_id: String, _dark: bool, accent: Color) -> void:
	var existing := content.get_node_or_null("PremiumSurfaceChrome")
	if existing != null:
		existing.queue_free()
	var chrome := Control.new()
	chrome.name = "PremiumSurfaceChrome"
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.z_index = 90
	content.add_child(chrome)
	var badge := PanelContainer.new()
	badge.position = Vector2(46, 16)
	badge.custom_minimum_size = Vector2(270, 52)
	badge.add_theme_stylebox_override("panel", Unjam3DTheme.badge(Unjam3DTheme.game_dark(game_id), 22))
	chrome.add_child(badge)
	var label := Label.new()
	label.text = "%s  •  %s" % [_game_name(game_id), _surface_name(surface)]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	Unjam3DTheme.label_3d(label, Color.WHITE, Unjam3DTheme.game_dark(game_id).darkened(0.35), 2)
	badge.add_child(label)

func _animate_surface(content: Control) -> void:
	# MotionDirector owns navigation transitions. This manager owns only skinning,
	# background and chrome so two systems never fight over content.modulate.
	content.modulate.a = 1.0
