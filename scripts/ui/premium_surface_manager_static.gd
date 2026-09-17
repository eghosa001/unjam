extends "res://scripts/ui/premium_surface_manager.gd"

# App-wide bridge for the new bright 3D visual language. Legacy gameplay
# mechanics stay untouched while levels, settings and collection surfaces are
# reskinned through one lightweight pass.

func _configure_background(root: Node, game_id: String, dark: bool, accent: Color) -> void:
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
		bg.configure(Unjam3DTheme.game_accent(game_id), dark)
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

func _polish_tree(node: Node, surface: String, dark: bool, accent: Color) -> void:
	if not is_instance_valid(node):
		return
	if node is Button and not _is_gameplay_widget(node):
		var button := node as Button
		button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 82.0)
		button.add_theme_font_size_override("font_size", maxi(21, button.get_theme_font_size("font_size")))
		var role := _role_for_surface_button(button, surface)
		var button_accent := _button_accent(role, accent)
		Unjam3DTheme.gloss_button(button, button_accent, role in ["primary", "reward", "success"], 24 if not _looks_like_level_button(button, surface) else 20, dark)
	elif node is PanelContainer:
		var panel := node as PanelContainer
		var emphasis := _panel_emphasis(panel, surface)
		var fill := Unjam3DTheme.surface_fill(dark, emphasis)
		var edge := Color(accent, 0.72) if dark or emphasis else Color("9adfff")
		panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(fill, 30 if emphasis else 25, edge, 3 if emphasis else 2, 11 if emphasis else 6))
	elif node is Label:
		var label := node as Label
		var base_font_size := label.get_theme_font_size("font_size")
		if label.has_meta("unjam_surface_base_font_size"):
			base_font_size = int(label.get_meta("unjam_surface_base_font_size"))
		elif base_font_size > 0:
			label.set_meta("unjam_surface_base_font_size", base_font_size)
		if base_font_size > 0:
			label.add_theme_font_size_override("font_size", base_font_size + (4 if base_font_size >= 28 else 2))
		var font_size := base_font_size
		var text := label.text.strip_edges().to_upper()
		var color := Unjam3DTheme.text_primary(dark)
		if "COIN" in text or "★" in text or "PRESTIGE" in text:
			color = Color("d88700")
		elif font_size >= 28 or text.begins_with("WORLD "):
			color = accent.lightened(0.28) if dark else Unjam3DTheme.game_dark(_game_id_from_accent(accent))
		Unjam3DTheme.label_3d(label, color, Color(1, 1, 1, 0.85), 2 if font_size < 24 else 3)
	elif node is ProgressBar:
		var progress := node as ProgressBar
		progress.add_theme_stylebox_override("background", Unjam3DTheme.panel_3d(Color("17304c") if dark else Color("d7efff"), 12, Color(accent, 0.55) if dark else Color("84d5ff"), 2, 2))
		progress.add_theme_stylebox_override("fill", Unjam3DTheme.panel_3d(accent, 12, accent.lightened(0.30), 2, 3))
	for child in node.get_children():
		if child.name == "Unjam3DSurfaceBackdrop":
			continue
		_polish_tree(child, surface, dark, accent)

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

func _add_surface_chrome(content: Control, _surface: String, _game_id: String, _dark: bool, _accent: Color) -> void:
	# Secondary screens already own their header/back navigation. Adding another
	# badge here duplicates that information and can overlap the native header.
	# Remove any older injected chrome atomically, then leave header ownership to
	# the screen itself while this manager continues to provide backdrop/skinning.
	var existing := content.get_node_or_null("PremiumSurfaceChrome")
	if existing != null:
		content.remove_child(existing)
		existing.queue_free()

func _animate_surface(content: Control) -> void:
	# MotionDirector owns navigation transitions. This manager owns only skinning,
	# background and chrome so two systems never fight over content.modulate.
	content.modulate.a = 1.0
