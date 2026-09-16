extends "res://scripts/ui/retention_hub.gd"

func make_button(text_value: String, accent: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 78)
	button.add_theme_font_size_override("font_size", 20)
	Unjam3DTheme.gloss_button(button, Unjam3DTheme.GREEN if accent else Unjam3DTheme.WATER_DARK, accent, 24)
	return button

func refresh() -> void:
	super.refresh()
	call_deferred("_apply_3d_retention_skin")

func _apply_3d_retention_skin() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		var script := child.get_script()
		if script is Script and String(script.resource_path).ends_with("premium_backdrop.gd") and child is CanvasItem:
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
	for child in node.get_children():
		if child.name == "Retention3DBackdrop":
			continue
		if child is Button:
			var button := child as Button
			var strong := "CLAIM" in button.text or "CHEST" in button.text
			Unjam3DTheme.gloss_button(button, Unjam3DTheme.GREEN if strong else Unjam3DTheme.WATER_DARK, strong, 24)
		elif child is PanelContainer:
			var panel := child as PanelContainer
			panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(0.96, 0.995, 1.0, 0.94), 30, Color("8edcff"), 2, 8))
		elif child is Label:
			var label := child as Label
			var size_value := label.get_theme_font_size("font_size")
			var text_value := label.text.to_upper()
			var color := Unjam3DTheme.NAVY
			if "◆" in text_value or "COINS" in text_value or "PRESTIGE" in text_value:
				color = Color("c87f00")
			elif size_value >= 28:
				color = Unjam3DTheme.GREEN_DARK
			Unjam3DTheme.label_3d(label, color, Color.WHITE, 2 if size_value < 24 else 3)
		_restyle_retention_tree(child)
