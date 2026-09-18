extends "res://scripts/ui/ux_shell_premium.gd"

var _cached_help_blocker: Control
var _help_layout_refresh_pending := false

func _main() -> Node:
	var parent := get_parent()
	if parent != null:
		return parent
	return super._main()

func _build_shell() -> void:
	super._build_shell()
	if not get_tree().node_added.is_connected(_on_casual_layout_node_added):
		get_tree().node_added.connect(_on_casual_layout_node_added)
	_compact_shell()
	_restyle_3d_shell()

func _on_casual_layout_node_added(node: Node) -> void:
	if node is Control and String(node.name) in ["BlockTray", "CompactGameFeedback", "CompactGameActions", "CompactProgressStrip"]:
		_cached_help_blocker = node as Control
		_queue_help_layout_refresh()

func _queue_help_layout_refresh() -> void:
	if _help_layout_refresh_pending:
		return
	_help_layout_refresh_pending = true
	call_deferred("_refresh_help_after_layout")

func _refresh_help_after_layout() -> void:
	if not is_inside_tree():
		_help_layout_refresh_pending = false
		return
	await get_tree().process_frame
	await get_tree().process_frame
	_help_layout_refresh_pending = false
	_layout_help_button()

func _after_shell_sync() -> void:
	_compact_shell()
	_queue_help_layout_refresh()
	_restyle_3d_shell()

func _apply_theme() -> void:
	super._apply_theme()
	_restyle_3d_shell()
	apply_theme_mode(theme_mode == "dark")

func apply_theme_mode(dark: bool) -> void:
	var main := _main()
	if main == null:
		return
	var game: Node = main.get("active_game") as Node
	if game == null or not is_instance_valid(game):
		game = main.get_node_or_null("ActiveGame")
	if game != null and game.has_method("apply_theme_mode"):
		game.call("apply_theme_mode", dark)

func _compact_shell() -> void:
	_layout_tutorial_panel()
	_layout_help_button()
	if theme_button != null:
		theme_button.visible = false

func _layout_help_button() -> void:
	if help_button == null:
		return
	help_button.text = "?"
	# The base shell anchors this control to the bottom-left. Switch to an
	# absolute top-left anchor before using viewport/global coordinates.
	help_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	help_button.custom_minimum_size = Vector2(80, 80)
	help_button.size = Vector2(80, 88)
	var viewport_size := get_viewport().get_visible_rect().size
	var desired := Vector2(24, maxf(24.0, viewport_size.y - 114.0))
	var blocker: Control = _gameplay_help_blocker()
	if blocker != null:
		var blocker_rect: Rect2 = blocker.get_global_rect()
		desired.y = minf(desired.y, maxf(24.0, blocker_rect.position.y - help_button.size.y - 16.0))
	help_button.global_position = desired
	help_button.add_theme_font_size_override("font_size", 32)
	help_button.tooltip_text = "How to play"

func _layout_tutorial_panel() -> void:
	if tutorial_panel == null or not is_instance_valid(tutorial_panel):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_width := clampf(viewport_size.x - 32.0, 340.0, 860.0)
	var panel_height := clampf(viewport_size.y - 48.0, 600.0, 1120.0)
	var panel_size := Vector2(panel_width, panel_height)
	tutorial_panel.custom_minimum_size = panel_size
	tutorial_panel.size = panel_size
	tutorial_panel.position = (viewport_size - panel_size) * 0.5
	if tutorial_title != null:
		tutorial_title.add_theme_font_size_override("font_size", 36 if viewport_size.x < 620.0 else 42)
	if tutorial_body != null:
		tutorial_body.add_theme_font_size_override("font_size", 24 if viewport_size.x < 620.0 else 29)
	var tabs := tutorial_panel.find_child("TutorialTabs", true, false) as HBoxContainer
	if tabs != null:
		for child in tabs.get_children():
			if child is Button:
				(child as Button).add_theme_font_size_override("font_size", 22 if viewport_size.x < 620.0 else 24)

func _restyle_3d_shell() -> void:
	if help_button != null:
		Unjam3DTheme.gloss_button(help_button, Unjam3DTheme.WATER_DARK, true, 28, theme_mode == "dark")
	if tutorial_layer == null or tutorial_panel == null:
		return
	var dim := tutorial_layer.get_node_or_null("TutorialDim") as ColorRect
	if dim != null:
		dim.color = Color(0.01, 0.18, 0.34, 0.72)
	var dark := theme_mode == "dark"
	var panel_fill := Color("142743") if dark else Color("f8fdff")
	var primary_text := Color("f4fbff") if dark else Unjam3DTheme.NAVY
	var body_text := Color("d5eaff") if dark else Color("315878")
	var text_outline := Color("071426") if dark else Color.WHITE
	tutorial_panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(panel_fill, 40, Color("66d4ff"), 4, 20))
	if tutorial_title != null:
		Unjam3DTheme.label_3d(tutorial_title, primary_text, text_outline, 3)
	if tutorial_body != null:
		Unjam3DTheme.label_3d(tutorial_body, body_text, text_outline, 2)
	_restyle_tutorial_children(tutorial_panel)

func _restyle_tutorial_children(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			var button := child as Button
			var strong := button.name == "TutorialClose"
			Unjam3DTheme.gloss_button(button, Unjam3DTheme.GREEN if strong else Unjam3DTheme.WATER_DARK, strong, 24, theme_mode == "dark")
		elif child is Label and child != tutorial_title and child != tutorial_body:
			var label := child as Label
			var dark := theme_mode == "dark"
			Unjam3DTheme.label_3d(label, Color("eaf6ff") if dark else Unjam3DTheme.NAVY, Color("071426") if dark else Color.WHITE, 2)
		_restyle_tutorial_children(child)

func _gameplay_help_blocker() -> Control:
	var main := _main()
	if main != null:
		for name in ["BlockTray", "CompactGameFeedback", "CompactGameActions", "CompactProgressStrip"]:
			var blocker := main.find_child(name, true, false) as Control
			if blocker != null and blocker.visible and blocker.is_visible_in_tree():
				_cached_help_blocker = blocker
				return blocker
	if _cached_help_blocker != null and is_instance_valid(_cached_help_blocker) 		and _cached_help_blocker.visible and _cached_help_blocker.is_visible_in_tree():
		return _cached_help_blocker
	_cached_help_blocker = null
	return null

func _find_named_control(node: Node, names: Array[String]) -> Control:
	if node is Control and String(node.name) in names:
		return node as Control
	for child in node.get_children():
		var found: Control = _find_named_control(child, names)
		if found != null:
			return found
	return null
