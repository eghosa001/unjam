extends "res://scripts/ui/retention_hub.gd"

func _dark_theme() -> bool:
	var scene := get_tree().current_scene
	var shell := scene.get_node_or_null("UXShell") if scene != null else null
	return shell != null and shell.get("theme_mode") != null and String(shell.get("theme_mode")) == "dark"

func make_button(text_value: String, accent: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	_style_retention_button(button, accent)
	return button

func _style_retention_button(button: Button, accent: bool) -> void:
	var dark := _dark_theme()
	var fill := Unjam3DTheme.GREEN.darkened(0.12) if accent else (Color("#343434") if dark else Color("#d8d4cc"))
	var edge := Unjam3DTheme.GREEN.lightened(0.12) if accent else (Color("#6a6257") if dark else Color("#b89b61"))
	var text_color := Color.WHITE if accent or dark else Color("#26323d")
	button.custom_minimum_size.y = 52.0
	button.add_theme_font_override("font", Unjam3DTheme.strong_font())
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", Unjam3DTheme.panel_3d(fill, 15, edge, 1, 5))
	button.add_theme_stylebox_override("hover", Unjam3DTheme.panel_3d(fill.lightened(0.06), 15, edge.lightened(0.10), 2, 6))
	button.add_theme_stylebox_override("pressed", Unjam3DTheme.panel_3d(fill.darkened(0.08), 15, edge, 1, 2))
	button.add_theme_stylebox_override("disabled", Unjam3DTheme.panel_3d(fill.darkened(0.10), 15, edge.darkened(0.14), 1, 2))
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", Color(text_color, 0.55))
	button.add_theme_constant_override("outline_size", 0)

func refresh() -> void:
	super.refresh()
	call_deferred("_apply_3d_retention_skin")

func _apply_3d_retention_skin() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		var script: Script = child.get_script() as Script
		if script != null and String(script.resource_path).ends_with("premium_backdrop.gd") and child is CanvasItem:
			(child as CanvasItem).visible = false
	var old_backdrop := get_node_or_null("Retention3DBackdrop")
	if old_backdrop != null:
		old_backdrop.queue_free()
	var backdrop := get_node_or_null("RetentionNeutralBackdrop") as ColorRect
	if backdrop == null:
		backdrop = ColorRect.new()
		backdrop.name = "RetentionNeutralBackdrop"
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.z_index = -100
		add_child(backdrop)
		move_child(backdrop, 0)
	backdrop.color = Color("#1d1d1d") if _dark_theme() else Color("#d8d4cc")
	_restyle_retention_tree(self)

func _restyle_retention_tree(node: Node) -> void:
	var dark := _dark_theme()
	for child in node.get_children():
		if child.name in ["RetentionNeutralBackdrop", "Retention3DBackdrop"]:
			continue
		if child is MarginContainer:
			var margin := child as MarginContainer
			margin.add_theme_constant_override("margin_left", 20)
			margin.add_theme_constant_override("margin_right", 20)
			margin.add_theme_constant_override("margin_top", 20)
			margin.add_theme_constant_override("margin_bottom", 20)
		elif child is VBoxContainer:
			var vbox := child as VBoxContainer
			vbox.add_theme_constant_override("separation", mini(12, vbox.get_theme_constant("separation")))
		elif child is HBoxContainer:
			var hbox := child as HBoxContainer
			hbox.add_theme_constant_override("separation", mini(8, hbox.get_theme_constant("separation")))
		elif child is Button:
			var button := child as Button
			var strong := "CLAIM" in button.text or "CHEST" in button.text or "OPEN" in button.text
			_style_retention_button(button, strong)
		elif child is PanelContainer:
			var panel := child as PanelContainer
			var panel_fill := Color("#252525") if dark else Color("#e3dfd7")
			var panel_edge := Color("#5b5347") if dark else Color("#b89b61")
			panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(panel_fill, 18, panel_edge, 1, 5))
		elif child is Label:
			var label := child as Label
			var original_size := label.get_theme_font_size("font_size")
			var target_size := 14
			if original_size >= 30:
				target_size = 23
			elif original_size >= 25:
				target_size = 20
			elif original_size >= 21:
				target_size = 18
			elif original_size >= 18:
				target_size = 15
			label.add_theme_font_size_override("font_size", target_size)
			var text_value := label.text.to_upper()
			var color := Color("#eef7ff") if dark else Color("#26323d")
			if "◆" in text_value or "COINS" in text_value or "PRESTIGE" in text_value:
				color = Color("#ffd166") if dark else Color("#8b6200")
			elif original_size >= 25:
				color = Color("#8ff0bd") if dark else Color("#137a49")
			var outline := Color("#11151a") if dark else Color(1, 1, 1, 0.65)
			Unjam3DTheme.label_3d(label, color, outline, 1)
		_restyle_retention_tree(child)
