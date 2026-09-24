extends Node

var tutorial_layer: CanvasLayer
var tutorial_panel: PanelContainer
var tutorial_title: Label
var tutorial_body: Label
var tutorial_demo: Label
var tutorial_step_label: Label
var tutorial_progress_label: Label
var tutorial_prev_button: Button
var tutorial_next_button: Button
var tutorial_steps: Array[String] = []
var tutorial_step_index := 0
var help_button: Button
var theme_button: Button
var tutorial_game := "rescue_rush"
var seen_this_session := {}
var tutorial_seen := {}
var theme_mode := "light"

const CONFIG_PATH := "user://unjam_ui.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_theme()
	_load_tutorial_seen()
	get_tree().node_added.connect(_on_node_added)
	var main := _main()
	if main != null and main.has_signal("surface_changed"):
		main.surface_changed.connect(_on_surface_changed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	call_deferred("_build_shell")
	call_deferred("_restyle_tree")

func _notification(what: int) -> void:
	if what == Node.NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_handle_back()
		get_viewport().set_input_as_handled()

func _on_surface_changed(surface: String) -> void:
	call_deferred("_sync_shell", surface)

func _on_viewport_size_changed() -> void:
	call_deferred("_sync_shell", _current_surface())

func _current_surface() -> String:
	var main := _main()
	if main != null and main.get("current_surface") != null:
		return String(main.get("current_surface"))
	return "home"

func _sync_shell(surface: String) -> void:
	if tutorial_panel == null:
		return
	if help_button != null:
		help_button.visible = surface == "game" and not tutorial_panel.visible
	if theme_button != null:
		theme_button.visible = surface == "settings" and not tutorial_panel.visible
		if theme_button.visible:
			theme_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			theme_button.position = Vector2(-350, -112)
			theme_button.custom_minimum_size = Vector2(310, 68)
			PremiumDesignSystem.apply_button(theme_button, theme_mode == "dark", _current_accent(), "secondary", 22)
	if surface == "game":
		var game_id := _current_game()
		if not bool(tutorial_seen.get(game_id, false)) and not bool(seen_this_session.get(game_id, false)):
			seen_this_session[game_id] = true
			call_deferred("show_tutorial", game_id)
	_after_shell_sync()

func _after_shell_sync() -> void:
	pass

func _build_shell() -> void:
	if tutorial_layer != null:
		return
	var dark := theme_mode == "dark"
	var accent := _current_accent()
	tutorial_layer = CanvasLayer.new()
	tutorial_layer.layer = 900
	add_child(tutorial_layer)

	help_button = Button.new()
	help_button.text = "?  HOW TO PLAY"
	help_button.custom_minimum_size = Vector2(280, 78)
	help_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help_button.position = Vector2(36, -102)
	help_button.add_theme_font_size_override("font_size", 20)
	help_button.pressed.connect(func(): show_tutorial(_current_game()))
	PremiumDesignSystem.apply_button(help_button, dark, accent, "utility", 22)
	tutorial_layer.add_child(help_button)

	theme_button = Button.new()
	theme_button.name = "ThemeToggle"
	theme_button.text = "☀  LIGHT THEME" if dark else "☾  DARK THEME"
	theme_button.custom_minimum_size = Vector2(310, 68)
	theme_button.add_theme_font_size_override("font_size", 17)
	theme_button.pressed.connect(_toggle_theme)
	PremiumDesignSystem.apply_button(theme_button, dark, accent, "secondary", 22)
	tutorial_layer.add_child(theme_button)

	var dim := ColorRect.new()
	dim.name = "TutorialDim"
	dim.color = Color(0.015, 0.025, 0.045, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_layer.add_child(dim)

	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.set_anchors_preset(Control.PRESET_CENTER)
	tutorial_panel.position = Vector2(-430, -500)
	tutorial_panel.custom_minimum_size = Vector2(860, 1000)
	tutorial_panel.visible = false
	PremiumDesignSystem.apply_panel(tutorial_panel, dark, accent, true, 36)
	tutorial_layer.add_child(tutorial_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	tutorial_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)

	var eyebrow := Label.new()
	eyebrow.text = "QUICK PLAY GUIDE"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 15)
	PremiumDesignSystem.apply_label(eyebrow, dark, "accent", accent)
	box.add_child(eyebrow)

	tutorial_title = Label.new()
	tutorial_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_title.add_theme_font_size_override("font_size", 38)
	PremiumDesignSystem.apply_label(tutorial_title, dark, "title", accent)
	box.add_child(tutorial_title)

	tutorial_body = Label.new()
	tutorial_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_body.add_theme_font_size_override("font_size", 21)
	PremiumDesignSystem.apply_label(tutorial_body, dark, "body", accent)
	box.add_child(tutorial_body)

	var demo_panel := PanelContainer.new()
	demo_panel.name = "TutorialDemoPanel"
	demo_panel.custom_minimum_size = Vector2(0, 190)
	PremiumDesignSystem.apply_panel(demo_panel, dark, accent, true, 30)
	box.add_child(demo_panel)
	var demo_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		demo_margin.add_theme_constant_override("margin_%s" % side, 18)
	demo_panel.add_child(demo_margin)
	var demo_box := VBoxContainer.new()
	demo_box.alignment = BoxContainer.ALIGNMENT_CENTER
	demo_box.add_theme_constant_override("separation", 10)
	demo_margin.add_child(demo_box)

	tutorial_demo = Label.new()
	tutorial_demo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_demo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_demo.add_theme_font_size_override("font_size", 48)
	PremiumDesignSystem.apply_label(tutorial_demo, dark, "title", accent)
	demo_box.add_child(tutorial_demo)

	tutorial_step_label = Label.new()
	tutorial_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_step_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_step_label.add_theme_font_size_override("font_size", 25)
	PremiumDesignSystem.apply_label(tutorial_step_label, dark, "body", accent)
	demo_box.add_child(tutorial_step_label)

	tutorial_progress_label = Label.new()
	tutorial_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_progress_label.add_theme_font_size_override("font_size", 15)
	PremiumDesignSystem.apply_label(tutorial_progress_label, dark, "accent", accent)
	box.add_child(tutorial_progress_label)

	var step_nav := HBoxContainer.new()
	step_nav.name = "TutorialStepNavigation"
	step_nav.add_theme_constant_override("separation", 10)
	box.add_child(step_nav)
	tutorial_prev_button = Button.new()
	tutorial_prev_button.text = "‹  BACK"
	tutorial_prev_button.custom_minimum_size = Vector2(0, 70)
	tutorial_prev_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_prev_button.pressed.connect(_tutorial_previous)
	PremiumDesignSystem.apply_button(tutorial_prev_button, dark, accent, "secondary", 22)
	step_nav.add_child(tutorial_prev_button)
	tutorial_next_button = Button.new()
	tutorial_next_button.text = "NEXT  ›"
	tutorial_next_button.custom_minimum_size = Vector2(0, 70)
	tutorial_next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_next_button.pressed.connect(_tutorial_next)
	PremiumDesignSystem.apply_button(tutorial_next_button, dark, accent, "primary", 22)
	step_nav.add_child(tutorial_next_button)

	var tabs := HBoxContainer.new()
	tabs.name = "TutorialTabs"
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	box.add_child(tabs)
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		var button := Button.new()
		button.text = _game_name(game_id)
		button.custom_minimum_size = Vector2(0, 62)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(show_tutorial.bind(game_id))
		PremiumDesignSystem.apply_button(button, dark, PremiumDesignSystem.accent_for_game(game_id), "secondary", 20)
		tabs.add_child(button)

	var close := Button.new()
	close.name = "TutorialClose"
	close.text = "PLAY NOW"
	close.custom_minimum_size = Vector2(0, 82)
	close.add_theme_font_size_override("font_size", 22)
	close.pressed.connect(hide_tutorial)
	PremiumDesignSystem.apply_button(close, dark, accent, "primary", 24)
	box.add_child(close)
	_sync_shell(_current_surface())

func _toggle_theme() -> void:
	theme_mode = "light" if theme_mode == "dark" else "dark"
	_save_config()
	_apply_theme()
	var main := _main()
	if main == null:
		return
	# PremiumHome watches theme_mode in its own state and rebuilds once.
	var live := main.get_node_or_null("PremiumLive")
	if live != null and live.visible and live.has_method("_build"):
		live.call_deferred("_build")
	var manager := main.get_node_or_null("PremiumSurfaceManager")
	if manager != null and manager.has_method("_refresh"):
		manager.call_deferred("_refresh", true)

func _apply_theme() -> void:
	if tutorial_layer == null:
		return
	var dark := theme_mode == "dark"
	var accent := _current_accent()
	if theme_button != null:
		theme_button.text = "☀  LIGHT THEME" if dark else "☾  DARK THEME"
		PremiumDesignSystem.apply_button(theme_button, dark, accent, "secondary", 22)
	if help_button != null:
		PremiumDesignSystem.apply_button(help_button, dark, accent, "utility", 22)
	if tutorial_panel != null:
		PremiumDesignSystem.apply_panel(tutorial_panel, dark, accent, true, 36)
	if tutorial_title != null:
		PremiumDesignSystem.apply_label(tutorial_title, dark, "title", accent)
	if tutorial_body != null:
		PremiumDesignSystem.apply_label(tutorial_body, dark, "body", accent)
	_restyle_tree()
	_sync_shell(_current_surface())

func show_tutorial(game_id: String = "rescue_rush") -> void:
	if tutorial_panel == null:
		return
	tutorial_game = game_id
	tutorial_step_index = 0
	tutorial_title.text = _game_name(game_id)
	match game_id:
		"water_sort":
			tutorial_body.text = "Sort every colour into its own tube. You only need three ideas."
			tutorial_steps = [
				"Tap a tube with liquid, then tap the tube you want to pour into.",
				"Pour only into an empty tube or onto the same colour. Each tube holds four layers.",
				"Use empty tubes as breathing room. UNDO repairs a mistake; HINT reveals a safe move."
			]
		"block_puzzle":
			tutorial_body.text = "Place all three shapes, clear lines and protect your future space."
			tutorial_steps = [
				"Touch and hold a piece. It lifts so the board stays visible under your finger.",
				"Drag to a valid position and release. Complete rows or columns disappear immediately.",
				"Look at all three pieces before committing. Keep the centre and long lanes flexible."
			]
		_:
			tutorial_body.text = "Free the trapped character by opening a clear route to the edge."
			tutorial_steps = [
				"Read the arrow. A piece can leave only in the direction it points.",
				"Tap it only when every square from the piece to the edge is clear.",
				"Special pieces can open gates or trigger chains. Clear the rescue lane to finish."
			]
	_render_tutorial_step()
	var dim := tutorial_layer.get_node("TutorialDim") as ColorRect
	dim.visible = true
	tutorial_panel.visible = true
	help_button.visible = false
	theme_button.visible = false
	var dark := theme_mode == "dark"
	PremiumDesignSystem.apply_panel(tutorial_panel, dark, PremiumDesignSystem.accent_for_game(game_id), true, 36)

func _tutorial_demo_for(game_id: String, step: int) -> String:
	match game_id:
		"water_sort":
			return ["▥  →  ▥", "●●  →  ●●", "▥  ◌  ▥"][clampi(step, 0, 2)]
		"block_puzzle":
			return ["◆  ⇧", "◆  →  ▦", "▦  ✦  ▦"][clampi(step, 0, 2)]
		_:
			return ["↗  →  EDGE", "■  ✕  ↗", "↗  ✦  ♥"][clampi(step, 0, 2)]

func _render_tutorial_step() -> void:
	if tutorial_steps.is_empty() or tutorial_step_label == null:
		return
	tutorial_step_index = clampi(tutorial_step_index, 0, tutorial_steps.size() - 1)
	tutorial_demo.text = _tutorial_demo_for(tutorial_game, tutorial_step_index)
	tutorial_step_label.text = tutorial_steps[tutorial_step_index]
	tutorial_progress_label.text = "STEP %d OF %d" % [tutorial_step_index + 1, tutorial_steps.size()]
	tutorial_prev_button.disabled = tutorial_step_index <= 0
	tutorial_next_button.disabled = tutorial_step_index >= tutorial_steps.size() - 1
	tutorial_next_button.text = "READY ✓" if tutorial_next_button.disabled else "NEXT  ›"

func _tutorial_next() -> void:
	if tutorial_step_index < tutorial_steps.size() - 1:
		tutorial_step_index += 1
		FeedbackManager.tap()
		_render_tutorial_step()

func _tutorial_previous() -> void:
	if tutorial_step_index > 0:
		tutorial_step_index -= 1
		FeedbackManager.tap()
		_render_tutorial_step()

func hide_tutorial() -> void:
	if tutorial_panel == null:
		return
	tutorial_seen[tutorial_game] = true
	_save_config()
	tutorial_panel.visible = false
	var dim := tutorial_layer.get_node("TutorialDim") as ColorRect
	dim.visible = false
	_sync_shell(_current_surface())

func _handle_back() -> void:
	if tutorial_panel != null and tutorial_panel.visible:
		hide_tutorial()
		return
	var main := _main()
	if main == null:
		return
	var coin_prompt := main.get_node_or_null("InsufficientCoinsPrompt")
	if coin_prompt != null and coin_prompt.get("overlay") != null:
		var coin_overlay = coin_prompt.get("overlay")
		if is_instance_valid(coin_overlay) and coin_overlay.visible:
			coin_prompt.call("_close")
			return
	var hub := main.get_node_or_null("MonetizationHub")
	if hub != null and hub.get("overlay") != null:
		var overlay = hub.get("overlay")
		if is_instance_valid(overlay) and overlay.visible:
			hub.call("_close_shop")
			return
	var surface := _current_surface()
	if surface == "game":
		if main.has_method("force_back_from_game"):
			main.call("force_back_from_game")
			return
		main.call("build_home")
	elif surface != "home":
		main.call("build_home")
	else:
		get_tree().quit()

func _current_accent() -> Color:
	return PremiumDesignSystem.accent_for_game(_current_game())

func _current_game() -> String:
	var main := _main()
	if main != null and main.get("selected_game_id") != null:
		var game_id := String(main.get("selected_game_id"))
		if game_id in PremiumDesignSystem.GAME_ACCENTS:
			return game_id
	return "rescue_rush"

func _game_name(game_id: String) -> String:
	match game_id:
		"water_sort": return "WATER SORT"
		"block_puzzle": return "BLOCK PUZZLE"
		_: return "RESCUE RUSH"

func _main() -> Node:
	return get_tree().current_scene

func _load_theme() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		theme_mode = String(cfg.get_value("appearance", "theme", "light"))
	if theme_mode not in ["light", "dark"]:
		theme_mode = "light"

func _load_tutorial_seen() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		tutorial_seen[game_id] = bool(cfg.get_value("tutorial", game_id, false))

func _save_config() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CONFIG_PATH)
	cfg.set_value("appearance", "theme", theme_mode)
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		cfg.set_value("tutorial", game_id, bool(tutorial_seen.get(game_id, false)))
	cfg.save(CONFIG_PATH)

func _on_node_added(node: Node) -> void:
	if node is Control and is_instance_valid(node):
		_soften_control(node)

func _restyle_tree() -> void:
	var root := _main()
	if root != null:
		_soften_control(root)
	if tutorial_layer != null:
		_soften_control(tutorial_layer)

func _script_path(node: Node) -> String:
	var script := node.get_script() as Script
	return String(script.resource_path) if script != null else ""

func _is_custom_surface(node: Node) -> bool:
	var cursor: Node = node
	while cursor != null:
		if cursor.has_meta("unjam_figma_reference_root"):
			return true
		if cursor.name in ["PremiumHome", "PremiumLive", "ActiveGame"]:
			return true
		var path := _script_path(cursor)
		if path.begins_with("res://scripts/game/") 			or path.ends_with("premium_home_overhaul.gd") 			or path.ends_with("premium_live_hub.gd") 			or path.ends_with("premium_result_overlay.gd") 			or path.ends_with("monetization_hub_3d.gd"):
			return true
		cursor = cursor.get_parent()
	return false

func _is_gameplay_widget(node: Node) -> bool:
	var path := _script_path(node)
	return path.contains("water_tube") or path.contains("block_piece_button") or path.contains("block_cell_button") or path.contains("premium_piece_button")

func _soften_control(node: Node) -> void:
	if not is_instance_valid(node) or _is_custom_surface(node):
		return
	var dark := theme_mode == "dark"
	var accent := _current_accent()
	if node is Button and not _is_gameplay_widget(node):
		var button := node as Button
		var role := "primary" if button.name == "TutorialClose" else PremiumDesignSystem.role_for_button(button)
		PremiumDesignSystem.apply_button(button, dark, accent, role, 22)
	elif node is PanelContainer:
		var panel := node as PanelContainer
		PremiumDesignSystem.apply_panel(panel, dark, accent, panel.name == "TutorialPanel", 34 if panel.name == "TutorialPanel" else 28)
	elif node is Label:
		var label := node as Label
		if not label.has_theme_color_override("font_color"):
			PremiumDesignSystem.apply_label(label, dark, "title" if label.get_theme_font_size("font_size") >= 30 else "body", accent)
	for child in node.get_children():
		_soften_control(child)
