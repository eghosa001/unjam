extends Node

const VIBRANT_REFERENCE_TARGET := "approved-colorful-reference"
var last_signature := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var main := get_parent()
	if main != null and main.has_signal("surface_changed"):
		main.surface_changed.connect(_on_surface_changed)
	call_deferred("_refresh", true)

func _on_surface_changed(_surface: String) -> void:
	call_deferred("_refresh", true)

func _refresh(force: bool) -> void:
	var main := get_parent()
	if main == null:
		return
	var surface := String(main.get("current_surface")) if main.get("current_surface") != null else "home"
	var game_id := String(main.get("selected_game_id")) if main.get("selected_game_id") != null else "rescue_rush"
	if game_id not in PremiumDesignSystem.GAME_ACCENTS:
		game_id = "rescue_rush"
	var shell := main.get_node_or_null("UXShell")
	var dark := true
	if shell != null and shell.get("theme_mode") != null:
		dark = String(shell.get("theme_mode")) == "dark"
	var content = main.get("content")
	var content_id := 0
	if content != null and is_instance_valid(content):
		content_id = content.get_instance_id()
	var signature := "%s|%s|%s|%d" % [surface, game_id, "dark" if dark else "light", content_id]
	if not force and signature == last_signature:
		return
	last_signature = signature
	if surface in ["home", "live", "game"]:
		return
	if content == null or not is_instance_valid(content):
		return
	var accent := PremiumDesignSystem.accent_for_game(game_id)
	_configure_background(content, game_id, dark, accent)
	_densify_layout(content, surface)
	_polish_tree(content, surface, game_id, dark, accent)
	_add_surface_chrome(content, surface, game_id, dark, accent)
	_animate_surface(content)

func _configure_background(root: Node, game_id: String, dark: bool, accent: Color) -> void:
	var backdrop: Node = _find_backdrop(root)
	if backdrop != null:
		var motif := 0
		match game_id:
			"water_sort": motif = 1
			"block_puzzle": motif = 2
		var gradient: Array = PremiumDesignSystem.game_gradient(game_id)
		var secondary: Color = gradient[1]
		var canvas := PremiumDesignSystem.vibrant_canvas(game_id)
		if dark:
			canvas = canvas.darkened(0.18)
		backdrop.call("configure", canvas, secondary, motif)
	PremiumVisuals.set_accent(accent)

func _densify_layout(content: Control, surface: String) -> void:
	_reduce_large_margins(content)
	if surface == "settings":
		var box := _find_first_vbox(content)
		if box != null:
			box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			box.offset_left = 36
			box.offset_right = -36
			box.offset_top = 78
			box.offset_bottom = -64
			box.custom_minimum_size = Vector2.ZERO
			box.alignment = BoxContainer.ALIGNMENT_CENTER
			box.add_theme_constant_override("separation", 22)

func _reduce_large_margins(node: Node) -> void:
	if node is MarginContainer:
		var margin := node as MarginContainer
		if margin.get_theme_constant("margin_left") > 28:
			margin.add_theme_constant_override("margin_left", 20)
		if margin.get_theme_constant("margin_right") > 28:
			margin.add_theme_constant_override("margin_right", 20)
		if margin.get_theme_constant("margin_top") > 44:
			margin.add_theme_constant_override("margin_top", 30)
		if margin.get_theme_constant("margin_bottom") > 44:
			margin.add_theme_constant_override("margin_bottom", 30)
	for child in node.get_children():
		_reduce_large_margins(child)

func _find_first_vbox(node: Node) -> VBoxContainer:
	for child in node.get_children():
		if child is VBoxContainer:
			return child as VBoxContainer
	for child in node.get_children():
		var found := _find_first_vbox(child)
		if found != null:
			return found
	return null

func _find_backdrop(node: Node) -> Node:
	if _script_path(node).ends_with("premium_backdrop.gd"):
		return node
	for child in node.get_children():
		var found: Node = _find_backdrop(child)
		if found != null:
			return found
	return null

func _script_path(node: Node) -> String:
	var script := node.get_script() as Script
	return String(script.resource_path) if script != null else ""

func _is_gameplay_widget(node: Node) -> bool:
	var path := _script_path(node)
	return path.contains("water_tube") or path.contains("block_piece_button") or path.contains("block_cell_button") or path.contains("premium_piece_button")

func _polish_tree(node: Node, surface: String, game_id: String, dark: bool, accent: Color) -> void:
	if not is_instance_valid(node):
		return
	if node is Button and not _is_gameplay_widget(node):
		var button := node as Button
		button.custom_minimum_size = Vector2(button.custom_minimum_size.x, maxf(button.custom_minimum_size.y, 84.0))
		button.add_theme_font_size_override("font_size", maxi(21, button.get_theme_font_size("font_size")))
		var role := _role_for_surface_button(button, surface)
		var radius := 18 if _looks_like_level_button(button, surface) else 24
		PremiumDesignSystem.apply_button(button, dark, accent, role, radius)
	elif node is PanelContainer:
		var panel := node as PanelContainer
		var emphasis := _panel_emphasis(panel, surface)
		_apply_vibrant_panel(panel, surface, game_id, dark, accent, emphasis)
	elif node is Label:
		var label := node as Label
		var fs := label.get_theme_font_size("font_size")
		if fs > 0:
			label.add_theme_font_size_override("font_size", fs + (6 if fs >= 28 else 3))
		_polish_label(label, dark, accent)
	elif node is ProgressBar:
		var progress := node as ProgressBar
		progress.add_theme_stylebox_override("background", PremiumDesignSystem.box(Color("143a67"), 9, Color("78d7ff"), 1, 0, true))
		progress.add_theme_stylebox_override("fill", PremiumDesignSystem.box(accent.lightened(0.10), 9, Color.WHITE, 1, 0, true))
	for child in node.get_children():
		_polish_tree(child, surface, game_id, dark, accent)

func _apply_vibrant_panel(panel: PanelContainer, surface: String, game_id: String, dark: bool, accent: Color, emphasis: bool) -> void:
	var gradient: Array = PremiumDesignSystem.game_gradient(game_id)
	var primary: Color = gradient[0]
	var secondary: Color = gradient[1]
	var fill := PremiumDesignSystem.vibrant_surface(game_id)
	if dark:
		fill = primary.darkened(0.52).lerp(secondary.darkened(0.50), 0.34)
	else:
		fill = fill.lerp(primary.lightened(0.52), 0.18)
	if surface == "settings":
		fill = fill.lerp(Color("7bdcff"), 0.12)
	elif surface == "collection":
		fill = fill.lerp(Color("f7a4ff"), 0.10)
	elif surface == "levels":
		fill = fill.lerp(Color("ffdd71"), 0.08)
	var edge := Color(accent.lightened(0.24), 0.92 if emphasis else 0.64)
	panel.add_theme_stylebox_override("panel", PremiumDesignSystem.box(fill, 32 if emphasis else 26, edge, 3 if emphasis else 2, 10 if emphasis else 5, dark))

func _role_for_surface_button(button: Button, surface: String) -> String:
	var text := button.text.strip_edges().to_upper()
	if surface == "settings":
		if text.ends_with(": ON"):
			return "success"
		if text.ends_with(": OFF"):
			return "toggle_off"
	if surface == "collection" and "OWNED" in text:
		return "success"
	if surface == "levels" and "CURRENT" in text:
		return "primary"
	return PremiumDesignSystem.role_for_button(button)

func _looks_like_level_button(button: Button, surface: String) -> bool:
	if surface != "levels":
		return false
	var text := button.text.strip_edges()
	if "\n" not in text:
		return false
	return text.get_slice("\n", 0).is_valid_int()

func _panel_emphasis(panel: PanelContainer, surface: String) -> bool:
	if panel.name in ["TutorialPanel", "HomeHero", "JourneyFill"]:
		return true
	if surface in ["collection", "levels", "settings"]:
		return panel.custom_minimum_size.y >= 90.0
	return false

func _polish_label(label: Label, dark: bool, accent: Color) -> void:
	var text := label.text.strip_edges().to_upper()
	var font_size := label.get_theme_font_size("font_size")
	if font_size >= 30 or text in ["SETTINGS", "RESCUE GARDEN"] or text.begins_with("WORLD "):
		PremiumDesignSystem.apply_label(label, dark, "title", accent)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.20))
		label.add_theme_constant_override("shadow_offset_y", 2)
	elif "COINS" in text or "★" in text or "PRESTIGE" in text:
		PremiumDesignSystem.apply_label(label, dark, "accent", PremiumDesignSystem.GOLD)
	elif font_size <= 19:
		PremiumDesignSystem.apply_label(label, dark, "muted", accent)
	elif not label.has_theme_color_override("font_color"):
		PremiumDesignSystem.apply_label(label, dark, "body", accent)

func _add_surface_chrome(content: Control, surface: String, game_id: String, dark: bool, accent: Color) -> void:
	var existing := content.get_node_or_null("PremiumSurfaceChrome")
	if existing != null:
		existing.queue_free()
	var chrome := Control.new()
	chrome.name = "PremiumSurfaceChrome"
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.z_index = 2
	content.add_child(chrome)

	var gradient: Array = PremiumDesignSystem.game_gradient(game_id)
	var top_line := ColorRect.new()
	top_line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_line.offset_bottom = 6
	top_line.color = Color(gradient[1], 0.92)
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(top_line)

	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	glow.offset_bottom = 230
	glow.color = Color(gradient[0], 0.09 if dark else 0.12)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(glow)

	var badge_panel := PanelContainer.new()
	badge_panel.position = Vector2(22, 14)
	badge_panel.custom_minimum_size = Vector2(280, 42)
	badge_panel.add_theme_stylebox_override("panel", PremiumDesignSystem.box(Color("ffffff", 0.82), 18, Color(gradient[0], 0.72), 2, 3, false))
	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(badge_panel)
	var badge := Label.new()
	badge.text = "%s  •  %s" % [_game_name(game_id), _surface_name(surface)]
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 15)
	badge.add_theme_color_override("font_color", gradient[1].darkened(0.35))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_panel.add_child(badge)

func _animate_surface(content: Control) -> void:
	content.modulate.a = 0.82
	var original := content.position
	content.position = original + Vector2(0, 8)
	var tween := content.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(content, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_property(content, "position", original, 0.30)

func _surface_name(surface: String) -> String:
	match surface:
		"levels": return "LEVEL JOURNEY"
		"collection": return "COLLECTION"
		"settings": return "SETTINGS"
		_: return surface.to_upper()

func _game_name(game_id: String) -> String:
	match game_id:
		"water_sort": return "WATER SORT"
		"block_puzzle": return "BLOCK PUZZLE"
		_: return "RESCUE RUSH"
