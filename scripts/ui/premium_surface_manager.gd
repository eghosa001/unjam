extends Node

var last_signature := ""
var timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_refresh", true)

func _process(delta: float) -> void:
	timer += delta
	if timer < 0.18:
		return
	timer = 0.0
	_refresh(false)

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
	_polish_tree(content, surface, dark, accent)
	_add_surface_chrome(content, surface, game_id, dark, accent)
	_animate_surface(content)

func _configure_background(root: Node, game_id: String, dark: bool, accent: Color) -> void:
	var backdrop := _find_backdrop(root)
	if backdrop != null:
		var motif := 0
		match game_id:
			"water_sort": motif = 1
			"block_puzzle": motif = 2
		backdrop.configure(PremiumDesignSystem.game_canvas(game_id, dark), accent, motif)
	var main := get_parent()
	if main != null:
		PremiumVisuals.set_accent(accent)

func _find_backdrop(node: Node) -> PremiumBackdrop:
	if node is PremiumBackdrop:
		return node as PremiumBackdrop
	for child in node.get_children():
		var found := _find_backdrop(child)
		if found != null:
			return found
	return null

func _polish_tree(node: Node, surface: String, dark: bool, accent: Color) -> void:
	if not is_instance_valid(node):
		return
	if node is Button and not node is WaterTubeButton and not node is BlockPieceButton and not node is PremiumPieceButton and not node is BlockCellButton:
		var button := node as Button
		var role := _role_for_surface_button(button, surface)
		var radius := 18 if _looks_like_level_button(button, surface) else 22
		PremiumDesignSystem.apply_button(button, dark, accent, role, radius)
	elif node is PanelContainer:
		var panel := node as PanelContainer
		var emphasis := _panel_emphasis(panel, surface)
		PremiumDesignSystem.apply_panel(panel, dark, accent, emphasis, 30 if emphasis else 26)
	elif node is Label:
		var label := node as Label
		_polish_label(label, surface, dark, accent)
	elif node is ProgressBar:
		var progress := node as ProgressBar
		progress.add_theme_stylebox_override("background", PremiumDesignSystem.box(PremiumDesignSystem.surface_3(dark), 8, PremiumDesignSystem.border(dark), 1, 0, dark))
		progress.add_theme_stylebox_override("fill", PremiumDesignSystem.box(accent, 8, accent.lightened(0.12), 1, 0, dark))
	for child in node.get_children():
		_polish_tree(child, surface, dark, accent)

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
	var first := text.get_slice("\n", 0)
	return first.is_valid_int()

func _panel_emphasis(panel: PanelContainer, surface: String) -> bool:
	if panel.name in ["TutorialPanel", "HomeHero", "JourneyFill"]:
		return true
	if surface in ["collection", "levels"]:
		var size := panel.custom_minimum_size
		return size.y >= 95.0
	return false

func _polish_label(label: Label, surface: String, dark: bool, accent: Color) -> void:
	var text := label.text.strip_edges().to_upper()
	var font_size := label.get_theme_font_size("font_size")
	if font_size >= 30 or text in ["SETTINGS", "RESCUE GARDEN"] or text.begins_with("WORLD "):
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
	chrome.z_index = -1
	content.add_child(chrome)
	content.move_child(chrome, 1 if content.get_child_count() > 1 else 0)

	var top_line := ColorRect.new()
	top_line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_line.offset_bottom = 4
	top_line.color = Color(accent, 0.72 if dark else 0.52)
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(top_line)

	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	glow.offset_bottom = 210
	glow.color = Color(accent, 0.035 if dark else 0.05)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(glow)

	var badge := Label.new()
	badge.position = Vector2(50, 18)
	badge.text = "%s  •  %s" % [_game_name(game_id), _surface_name(surface)]
	badge.add_theme_font_size_override("font_size", 13)
	badge.add_theme_color_override("font_color", Color(accent, 0.82))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(badge)

func _animate_surface(content: Control) -> void:
	content.modulate.a = 0.0
	var original := content.position
	content.position = original + Vector2(0, 10)
	var tween := content.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(content, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(content, "position", original, 0.24)

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
