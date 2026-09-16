extends "res://scripts/ui/ux_shell_premium.gd"

func _main() -> Node:
	var parent := get_parent()
	if parent != null:
		return parent
	return super._main()

func _build_shell() -> void:
	super._build_shell()
	_compact_shell()

func _after_shell_sync() -> void:
	_compact_shell()

func _compact_shell() -> void:
	if help_button != null:
		help_button.text = "?"
		help_button.custom_minimum_size = Vector2(72, 72)
		help_button.size = Vector2(72, 72)
		# CanvasLayer is not a Control parent, so anchor presets do not provide a
		# usable bottom-left reference. Position directly in viewport coordinates,
		# then lift above any gameplay footer that occupies the same space.
		var viewport_size := get_viewport().get_visible_rect().size
		var desired := Vector2(24, maxf(24.0, viewport_size.y - 96.0))
		var footer: Control = _gameplay_footer()
		if footer != null and footer.visible and footer.is_visible_in_tree():
			var proposed := Rect2(desired, Vector2(72, 72))
			var footer_rect: Rect2 = footer.get_global_rect()
			if proposed.intersects(footer_rect):
				desired.y = maxf(24.0, footer_rect.position.y - 84.0)
		help_button.position = desired
		help_button.add_theme_font_size_override("font_size", 28)
		help_button.tooltip_text = "How to play"
	if theme_button != null:
		# Appearance is already a first-class Settings row; a second floating
		# theme control is redundant and adds visual noise.
		theme_button.visible = false

func _gameplay_footer() -> Control:
	var main := _main()
	if main == null:
		return null
	var game: Node = main.get("active_game") as Node
	if game == null or not is_instance_valid(game):
		game = main.get_node_or_null("ActiveGame")
	if game == null:
		return null
	return _find_named_control(game, ["CompactGameActions", "CompactProgressStrip"])

func _find_named_control(node: Node, names: Array[String]) -> Control:
	if node is Control and String(node.name) in names:
		return node as Control
	for child in node.get_children():
		var found: Control = _find_named_control(child, names)
		if found != null:
			return found
	return null
