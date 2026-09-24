extends "res://scripts/ui/retention_hub.gd"

func _dark_theme() -> bool:
	var scene := get_tree().current_scene
	var shell := scene.get_node_or_null("UXShell") if scene != null else null
	return shell != null and shell.get("theme_mode") != null and String(shell.get("theme_mode")) == "dark"

func make_button(text_value: String, accent: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 88)
	button.add_theme_font_size_override("font_size", 24)
	Unjam3DTheme.gloss_button(button, Unjam3DTheme.GREEN if accent else Unjam3DTheme.WATER_DARK, accent, 24)
	return button

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
	var backdrop := get_node_or_null("Retention3DBackdrop") as Unjam3DBackdrop
	if backdrop == null:
		backdrop = Unjam3DBackdrop.new()
		backdrop.name = "Retention3DBackdrop"
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop.z_index = -100
		add_child(backdrop)
		move_child(backdrop, 0)
	backdrop.configure(Unjam3DTheme.GREEN)
	_restyle_retention_tree(self)

func _restyle_retention_tree(node: Node) -> void:
	var dark := _dark_theme()
	for child in node.get_children():
		if child.name == "Retention3DBackdrop":
			continue
		if child is Button:
			var button := child as Button
			var strong := "CLAIM" in button.text or "CHEST" in button.text
			button.add_theme_font_size_override("font_size", maxi(24, button.get_theme_font_size("font_size")))
			button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 88.0)
			Unjam3DTheme.gloss_button(button, Unjam3DTheme.GREEN if strong else Unjam3DTheme.WATER_DARK, strong, 24)
		elif child is PanelContainer:
			var panel := child as PanelContainer
			var panel_fill := Color("#252525") if dark else Color("#d8d4cc")
			var panel_edge := Color("#5b5347") if dark else Color("#b89b61")
			panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(panel_fill, 30, panel_edge, 2, 8))
		elif child is Label:
			var label := child as Label
			var size_value := label.get_theme_font_size("font_size")
			var minimum_size := 22
			if size_value >= 28:
				minimum_size = 34
			elif size_value >= 24:
				minimum_size = 30
			elif size_value >= 20:
				minimum_size = 26
			elif size_value >= 17:
				minimum_size = 23
			label.add_theme_font_size_override("font_size", maxi(size_value, minimum_size))
			var text_value := label.text.to_upper()
			var color := Color("#eef7ff") if dark else Unjam3DTheme.NAVY
			if "◆" in text_value or "COINS" in text_value or "PRESTIGE" in text_value:
				color = Color("#ffd166") if dark else Color("#9a6500")
			elif size_value >= 28:
				color = Color("#8ff0bd") if dark else Unjam3DTheme.GREEN_DARK
			var outline := Color("#11151a") if dark else Color.WHITE
			Unjam3DTheme.label_3d(label, color, outline, 2 if size_value < 24 else 3)
		_restyle_retention_tree(child)
