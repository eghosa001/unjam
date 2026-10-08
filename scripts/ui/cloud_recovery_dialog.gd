extends CanvasLayer

const UI = preload("res://scripts/ui/figma_reference_canvas.gd")
const INK := Color("#f5f7fa")
const MUTED := Color("#bdcad8")
const ACCENT := Color("#3c9bf5")

var _confirm_code := ""
var _restore_input: LineEdit
var _restore_button: Button
var _status: Label

func _ready() -> void:
	layer = 105
	var shade := ColorRect.new()
	shade.name = "CloudRecoveryShade"
	shade.color = Color(0.01, 0.02, 0.04, 0.83)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.position = Vector2.ZERO
	shade.size = get_viewport().get_visible_rect().size
	add_child(shade)
	shade.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			queue_free()
	)
	var center := CenterContainer.new()
	center.name = "CloudRecoveryCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.position = Vector2.ZERO
	center.size = get_viewport().get_visible_rect().size
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var card := PanelContainer.new()
	card.name = "CloudRecoveryCard"
	card.custom_minimum_size.x = minf(350.0, get_viewport().get_visible_rect().size.x - 24.0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", UI.solid_box(Color("#1d2a3a"), 18, Color("#4c657e"), 2))
	center.add_child(card)
	var margins := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + side, 18)
	card.add_child(margins)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)
	margins.add_child(stack)

	_add_label(stack, "CLOUD BACKUP", 23, INK, false)
	_add_label(stack, "Your private code restores gameplay progress after reinstalling. It is not a Google Play purchase receipt.", 13, MUTED, true)
	_add_label(stack, "YOUR PRIVATE RECOVERY CODE", 14, ACCENT, false)
	var code := CloudSaveManager.recovery_code()
	for i in range(4):
		var value := code.substr(i * 16, 16).to_upper() if code.length() == 64 else "NOT AVAILABLE"
		_add_label(stack, value, 17, INK, false)
	var copy := _add_button(stack, "COPY CODE", ACCENT)
	copy.disabled = code.is_empty()
	copy.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(code)
		_status.text = "Copied. Keep this private and store it safely."
	)
	_add_label(stack, "RESTORE EXISTING BACKUP", 14, ACCENT, false)
	_restore_input = LineEdit.new()
	_restore_input.name = "RecoveryCodeInput"
	_restore_input.placeholder_text = "Paste 64-character recovery code"
	_restore_input.max_length = 80
	_restore_input.add_theme_font_size_override("font_size", 14)
	_restore_input.add_theme_color_override("font_color", INK)
	_restore_input.add_theme_color_override("font_placeholder_color", MUTED)
	_restore_input.add_theme_stylebox_override("normal", UI.solid_box(Color("#28394e"), 10, ACCENT, 1))
	_restore_input.custom_minimum_size.y = 46
	stack.add_child(_restore_input)
	_restore_button = _add_button(stack, "RESTORE BACKUP", Color("#24b89e"))
	_restore_button.pressed.connect(_restore_pressed)
	_status = _add_label(stack, "Restoring replaces this device's gameplay progress. Purchases remain linked to Google Play.", 12, MUTED, true)
	_status.name = "CloudRecoveryStatus"
	var close := _add_button(stack, "CLOSE", Color("#35485f"))
	close.pressed.connect(queue_free)

func _add_label(parent: Node, message: String, font_size: int, color: Color, wrap: bool) -> Label:
	var label := UI.label(message, font_size, color, font_size >= 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _add_button(parent: Node, text_value: String, fill: Color) -> Button:
	var button := UI.premium_button(text_value, 15, Color.WHITE, fill, 13)
	button.custom_minimum_size.y = 48
	button.focus_mode = Control.FOCUS_ALL
	parent.add_child(button)
	return button

func _restore_pressed() -> void:
	var code := _restore_input.text.strip_edges().replace(" ", "").replace("-", "").to_lower()
	if code.length() != 64:
		_status.text = "Paste a valid 64-character backup code."
		_confirm_code = ""
		_restore_button.text = "RESTORE BACKUP"
		return
	if code != _confirm_code:
		_confirm_code = code
		_status.text = "This overwrites local game progress. Press CONFIRM RESTORE to continue."
		_restore_button.text = "CONFIRM RESTORE"
		return
	_confirm_code = ""
	_restore_button.disabled = true
	_status.text = "Checking cloud backup before replacing local progress..."
	CloudSaveManager.restore_from_recovery_code(code, func(ok: bool, message: String) -> void:
		if not is_instance_valid(_status) or not is_instance_valid(_restore_button):
			return
		_status.text = message
		_restore_button.disabled = false
		_restore_button.text = "RESTORE BACKUP"
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
