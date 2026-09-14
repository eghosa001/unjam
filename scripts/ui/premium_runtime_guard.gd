extends Node

var scan_elapsed := 0.0
var last_surface := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)

func _process(delta: float) -> void:
	scan_elapsed += delta
	var main := get_parent()
	if main == null:
		return
	_enforce_shell_safety(main)
	_enforce_result_state(main)
	if scan_elapsed >= 0.20:
		scan_elapsed = 0.0
		_polish_buttons(main)
		_polish_surface_transition(main)

func _enforce_shell_safety(main: Node) -> void:
	var shell := main.get_node_or_null("UXShell")
	if shell == null:
		return
	var shell_logo = shell.get("logo")
	if shell_logo != null and is_instance_valid(shell_logo):
		shell_logo.visible = false
	var active = main.get("active_game")
	var in_result := false
	if active != null and is_instance_valid(active):
		var rescued = active.get("rescued")
		var completed = active.get("completed")
		in_result = (rescued != null and bool(rescued)) or (completed != null and bool(completed))
	if in_result:
		var help = shell.get("help_button")
		var theme = shell.get("theme_button")
		if help != null and is_instance_valid(help):
			help.visible = false
		if theme != null and is_instance_valid(theme):
			theme.visible = false

func _enforce_result_state(main: Node) -> void:
	var active = main.get("active_game")
	if active == null or not is_instance_valid(active):
		return
	if String(active.name) != "ActiveGame":
		return
	var rescued = active.get("rescued")
	if rescued == null or not bool(rescued):
		return
	var board = active.get("board_panel")
	if board != null and is_instance_valid(board):
		board.visible = false
	var hint = active.get("hint_label")
	if hint != null and is_instance_valid(hint):
		hint.visible = false
	for child in active.get_children():
		if child is ColorRect:
			var overlay := child as ColorRect
			if overlay.color.a >= 0.90:
				overlay.z_index = 2000
				overlay.mouse_filter = Control.MOUSE_FILTER_STOP
				if not overlay.has_meta("premium_result_reveal"):
					overlay.set_meta("premium_result_reveal", true)
					overlay.modulate.a = 0.0
					var tween := overlay.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					tween.tween_property(overlay, "modulate:a", 1.0, 0.22)

func _polish_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			_install_button_motion(child as Button)
		_polish_buttons(child)

func _install_button_motion(button: Button) -> void:
	if button.has_meta("unjam_premium_motion"):
		return
	if button is PremiumPieceButton or button is WaterTubeButton or button is BlockPieceButton or button is BlockCellButton:
		return
	button.set_meta("unjam_premium_motion", true)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.resized.connect(func():
		if is_instance_valid(button):
			button.pivot_offset = button.size * 0.5
	)
	button.pivot_offset = button.size * 0.5
	button.mouse_entered.connect(_button_hover.bind(button, true))
	button.mouse_exited.connect(_button_hover.bind(button, false))
	button.button_down.connect(_button_press.bind(button))
	button.button_up.connect(_button_release.bind(button))

func _button_hover(button: Button, entering: bool) -> void:
	if not is_instance_valid(button) or button.disabled:
		return
	var target := Vector2(1.025, 1.025) if entering else Vector2.ONE
	var tween := button.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target, 0.11)

func _button_press(button: Button) -> void:
	if not is_instance_valid(button) or button.disabled:
		return
	var tween := button.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.965, 0.965), 0.055)

func _button_release(button: Button) -> void:
	if not is_instance_valid(button):
		return
	var tween := button.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.035, 1.035), 0.075)
	tween.tween_property(button, "scale", Vector2.ONE, 0.13)

func _polish_surface_transition(main: Node) -> void:
	var raw_surface = main.get("current_surface")
	var surface := String(raw_surface) if raw_surface != null else "home"
	if surface == last_surface:
		return
	last_surface = surface
	var content = main.get("content")
	if content is Control and is_instance_valid(content) and content.visible:
		content.modulate.a = 0.0
		content.position.y += 14.0
		var tween := content.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(content, "modulate:a", 1.0, 0.18)
		tween.tween_property(content, "position:y", content.position.y - 14.0, 0.22)
