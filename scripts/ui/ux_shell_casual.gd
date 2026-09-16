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
		# CanvasLayer is not a Control parent, so anchor presets do not provide a
		# usable bottom-left reference. Position directly in viewport coordinates.
		var viewport_size := get_viewport().get_visible_rect().size
		help_button.position = Vector2(24, maxf(24.0, viewport_size.y - 96.0))
		help_button.add_theme_font_size_override("font_size", 28)
		help_button.tooltip_text = "How to play"
	if theme_button != null:
		# Appearance is already a first-class Settings row; a second floating
		# theme control is redundant and adds visual noise.
		theme_button.visible = false
