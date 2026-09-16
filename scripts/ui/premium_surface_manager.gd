extends Node

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
	# Home, Live and active gameplay have dedicated premium builders; every other
	# user-facing surface is normalized here so no legacy flat screen remains.
	if surface in ["home", "live", "game"]:
		return
	if content == null or not is_instance_valid(content):
		return
	var accent := PremiumDesignSystem.accent_for_game(game_id)
	_configure_background(content, game_id, dark, accent)
	_polish_tree(content, surface, dark, accent)
	_add_surface_chrome(content, surface, game_id, dark, accent)
	_animate_surface(content)

func _configure_background(root: Node, game_id: String, dark: bool, accent: Color) -> void:
	var backdrop: Node = _find_backdrop(root)
	if backdrop != null:
		var motif := 0
		match game_id:
			"water_sort": motif = 1
			"block_puzzle": motif = 2
		backdrop.call("configure", PremiumDesignSystem.game_canvas(game_id, dark), accent, motif)
	PremiumVisuals.set_accent(accent)

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

func _polish_tree(node: Node, surface: String, dark: bool, accent: Color) -> void:
	if not is_instance_valid(node):
		return
	if node is Button and not _is_gameplay_widget(node):
		var button := node as Button
		button.custom_minimum_size = Vector2(button.custom_minimum_size.x, maxf(button.custom_minimum_size.y, 82.0))
		button.add_theme_font_size_override("font_size", maxi(20, button.get_theme_font_size("font_size")))
		var role := _role_for_surface_button(button, surface)
		var radius := 18 if _looks_like_level_button(button, surface) else 24
		PremiumDesignSystem.apply_button(button, dark, accent, role, radius)
	elif node is PanelContainer:
		var panel := node as PanelContainer
		var emphasis := _panel_emphasis(panel, surface)
		if panel.name in ["GameplayStage", "GameplayBoardHolder"]:
			PremiumDesignSystem.apply_recessed_panel(panel, dark, accent, 30)
		else:
			PremiumDesignSystem.apply_panel(panel, dark, accent, emphasis, 32 if emphasis else 26)
	elif node is Label:
		var label := node as Label
		var fs := label.get_theme_font_size("font_size")
		if fs > 0:
			label.add_theme_font_size_override("font_size", fs + (5 if fs >= 28 else 3))
		_polish_label(label, dark, accent)
	elif node is ProgressBar:
		var progress := node as ProgressBar
		progress.add_theme_stylebox_override("background", PremiumDesignSystem.recessed_box(PremiumDesignSystem.surface_3(dark), 10, PremiumDesignSystem.border(dark), dark))
		progress.add_theme_stylebox_override("fill", PremiumDesignSystem.gloss_button(accent, 10, dark, 2))
	for child in node.get_children():
		_polish_tree(child, surface, dark, accent)

func _role_for_surface_button(button: Button, surface: String) -> String:
	var text := button.text.strip_edges().to_upper()
	if surface == "settings":
		if text.ends_with(": ON") or "•   ON" in text:
			return "success"
		if text.ends_with(": OFF") or "•   OFF" in text:
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
	if panel.name in ["TutorialPanel", "HomeHero", "JourneyFill", "Sanctuary", "CompactGameInfo"]:
		return true
	if surface in ["collection", "levels", "settings", "shop"]:
		return panel.custom_minimum_size.y >= 88.0
	return false

func _polish_label(label: Label, dark: bool, accent: Color) -> void:
	var text := label.text.strip_edges().to_upper()
	var font_size := label.get_theme_font_size("font_size")
	if font_size >= 30 or text in ["SETTINGS", "RESCUE GARDEN", "COLLECTION", "SHOP"] or text.begins_with("WORLD "):
		PremiumDesignSystem.apply_label(label, dark, "title", accent)
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

	var top_glow := ColorRect.new()
	top_glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_glow.offset_bottom = 170
	top_glow.color = Color(accent, 0.045 if dark else 0.065)
	top_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(top_glow)

	var top_line := ColorRect.new()
	top_line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_line.offset_bottom = 5
	top_line.color = Color(accent.lightened(0.20), 0.82 if dark else 0.62)
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(top_line)

	var badge := Label.new()
	badge.position = Vector2(50, 18)
	badge.text = "%s  •  %s" % [_game_name(game_id), _surface_name(surface)]
	badge.add_theme_font_size_override("font_size", 15)
	badge.add_theme_color_override("font_color", Color(accent, 0.88))
	badge.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.24))
	badge.add_theme_constant_override("shadow_offset_y", 2)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(badge)

func _animate_surface(content: Control) -> void:
	if MotionSystem.reduced():
		content.modulate.a = 1.0
		return
	content.modulate.a = 0.88
	var original := content.position
	content.position = original + Vector2(0, 10)
	var tween := content.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(content, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_property(content, "position", original, 0.28)

func _surface_name(surface: String) -> String:
	match surface:
		"levels": return "LEVEL JOURNEY"
		"collection": return "COLLECTION"
		"settings": return "SETTINGS"
		"shop": return "SHOP"
		"daily": return "DAILY"
		_: return surface.to_upper()

func _game_name(game_id: String) -> String:
	match game_id:
		"water_sort": return "WATER SORT"
		"block_puzzle": return "BLOCK PUZZLE"
		_: return "RESCUE RUSH"
