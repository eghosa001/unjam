extends "res://scripts/ui/ux_shell_premium.gd"

func _build_shell() -> void:
	super._build_shell()
	_compact_shell()

func _process(delta: float) -> void:
	super._process(delta)
	_compact_shell()

func _compact_shell() -> void:
	if help_button != null:
		help_button.text = "?"
		help_button.custom_minimum_size = Vector2(72, 72)
		help_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		help_button.position = Vector2(24, -92)
		help_button.add_theme_font_size_override("font_size", 28)
		help_button.tooltip_text = "How to play"
	if theme_button != null:
		# Appearance is already a first-class Settings row; a second floating
		# theme control is redundant and adds visual noise.
		theme_button.visible = false
