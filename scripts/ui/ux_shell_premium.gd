extends "res://scripts/ui/ux_shell.gd"

func _process(delta: float) -> void:
	super._process(delta)
	var main := _main()
	if main == null:
		return
	var raw_surface = main.get("current_surface")
	var surface := String(raw_surface) if raw_surface != null else "home"
	# Home/Live own their navigation. Settings deliberately keeps the appearance
	# control visible so light/dark mode is actually reachable from the premium UI.
	if help_button != null:
		help_button.visible = surface == "game" and not tutorial_panel.visible
	if theme_button != null:
		theme_button.visible = surface == "settings" and not tutorial_panel.visible
		if theme_button.visible:
			theme_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			theme_button.position = Vector2(-350, -112)
			theme_button.custom_minimum_size = Vector2(310, 68)
			PremiumDesignSystem.apply_button(theme_button, theme_mode == "dark", _current_accent(), "secondary", 22)
	var hub := main.get_node_or_null("MonetizationHub")
	if hub != null and hub.get("shop_button") != null:
		var shop = hub.get("shop_button")
		if is_instance_valid(shop):
			shop.visible = false

func _current_accent() -> Color:
	var main := _main()
	if main != null and main.get("selected_game_id") != null:
		return PremiumDesignSystem.accent_for_game(String(main.get("selected_game_id")))
	return PremiumDesignSystem.accent_for_game("rescue_rush")

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
	if _is_custom_surface(node):
		return
	var dark := theme_mode == "dark"
	var accent := _current_accent()
	if node is Button and not node is WaterTubeButton and not node is BlockPieceButton and not node is PremiumPieceButton and not node is BlockCellButton:
		var button := node as Button
		var role := "primary" if button.name == "TutorialClose" else PremiumDesignSystem.role_for_button(button)
		PremiumDesignSystem.apply_button(button, dark, accent, role, 22)
	elif node is PanelContainer:
		var panel := node as PanelContainer
		if panel.name == "TutorialPanel":
			PremiumDesignSystem.apply_panel(panel, dark, accent, true, 34)
		elif not panel.has_theme_stylebox_override("panel"):
			PremiumDesignSystem.apply_panel(panel, dark, accent, false, 28)
	elif node is Label:
		var label := node as Label
		if not label.has_theme_color_override("font_color"):
			var font_size := label.get_theme_font_size("font_size")
			PremiumDesignSystem.apply_label(label, dark, "title" if font_size >= 30 else "body", accent)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.0))
	for child in node.get_children():
		_soften_control(child)
