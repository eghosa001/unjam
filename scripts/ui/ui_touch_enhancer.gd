extends Node
class_name UiTouchEnhancer

var host: Control
var scan_elapsed := 0.0
var drag_piece_index := -1
var drag_press_position := Vector2.ZERO
var drag_active := false
var drag_hover_origin := Vector2i(-1, -1)

func _ready() -> void:
	host = get_parent() as Control
	set_process(true)
	set_process_input(true)
	call_deferred("_apply_enhancements")

func _process(delta: float) -> void:
	scan_elapsed += delta
	if scan_elapsed >= 0.35:
		scan_elapsed = 0.0
		_apply_enhancements()

func _apply_enhancements() -> void:
	if host == null or not is_instance_valid(host):
		return
	_enlarge_buttons(host)
	if host.name == "BlockPuzzle":
		var hint = host.get("hint_label")
		if hint is Label:
			hint.add_theme_font_size_override("font_size", 20)
			hint.custom_minimum_size = Vector2(0, 44)
			if hint.text.is_empty() or hint.text.begins_with("Select a shape"):
				hint.text = "Drag a shape onto the grid • tap placement still works"
	elif host.name == "WaterSort":
		var hint = host.get("hint_label")
		if hint is Label:
			hint.add_theme_font_size_override("font_size", 20)
			hint.custom_minimum_size = Vector2(0, 44)

func _enlarge_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			_apply_button_size(child)
		_enlarge_buttons(child)

func _apply_button_size(button: Button) -> void:
	var label := button.text.strip_edges().to_upper()
	var wanted := button.custom_minimum_size
	match host.name:
		"Game":
			if label == "BACK" or label == "RETRY": wanted = Vector2(160, 82)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(300, 92)
			elif label.contains("NEXT RESCUE") or label.contains("BACK HOME"): wanted = Vector2(520, 98)
			elif label.contains("DOUBLE BASE REWARD"): wanted = Vector2(520, 92)
		"WaterSort":
			if button is WaterTubeButton: wanted = Vector2(170, 330)
			elif label.contains("BACK"): wanted = Vector2(180, 82)
			elif label == "RETRY": wanted = Vector2(170, 82)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(270, 88)
		"BlockPuzzle":
			if _is_block_piece_button(button): wanted = Vector2(310, 150)
			elif label.contains("BACK"): wanted = Vector2(175, 82)
			elif label == "RETRY": wanted = Vector2(165, 82)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(290, 86)
		"Main":
			if label.begins_with("PLAY"): wanted = Vector2(270, 100)
			elif label == "CONTINUE": wanted = Vector2(270, 72)
			elif label.contains("DAILY REWARD") or label.ends_with("\nDONE"): wanted = Vector2(326, 110)
			elif label == "COLLECTION" or label == "SETTINGS": wanted = Vector2(326, 94)
			elif label == "←": wanted = Vector2(120, 82)
			elif label.contains("PREV") or label == "CURRENT" or label.contains("NEXT"): wanted = Vector2(240, 76)
	if wanted.x > button.custom_minimum_size.x or wanted.y > button.custom_minimum_size.y:
		button.custom_minimum_size = Vector2(maxf(wanted.x, button.custom_minimum_size.x), maxf(wanted.y, button.custom_minimum_size.y))

func _is_block_piece_button(button: Button) -> bool:
	var script: Script = button.get_script() as Script
	return script != null and String(script.resource_path).ends_with("block_piece_button.gd")

func _input(event: InputEvent) -> void:
	if host == null or host.name != "BlockPuzzle" or bool(host.get("completed")):
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_finish_drag(event.position)
	elif event is InputEventScreenDrag:
		_update_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_finish_drag(event.position)
	elif event is InputEventMouseMotion and drag_piece_index >= 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_drag(event.position)

func _begin_drag(position: Vector2) -> void:
	drag_piece_index = _piece_at(position)
	drag_press_position = position
	drag_active = false
	drag_hover_origin = Vector2i(-1, -1)

func _piece_at(position: Vector2) -> int:
	var row: Variant = host.get("piece_row")
	if not row is HBoxContainer:
		return -1
	for i in range(row.get_child_count()):
		var child: Node = row.get_child(i)
		if child is Control and child.visible and not child.disabled and child.get_global_rect().has_point(position):
			return i
	return -1

func _cell_at(position: Vector2) -> Vector2i:
	var buttons: Variant = host.get("cell_buttons")
	if not buttons is Array:
		return Vector2i(-1, -1)
	for i in range(buttons.size()):
		var cell = buttons[i]
		if cell is Control and cell.visible and cell.get_global_rect().has_point(position):
			return Vector2i(i % 8, int(i / 8))
	return Vector2i(-1, -1)

func _update_drag(position: Vector2) -> void:
	var pieces = host.get("pieces")
	if not pieces is Array or drag_piece_index < 0 or drag_piece_index >= pieces.size():
		return
	var shape = pieces[drag_piece_index]
	if not shape is Array or shape.is_empty():
		return
	if not drag_active and position.distance_to(drag_press_position) < 18.0:
		return
	drag_active = true
	var origin := _cell_at(position)
	if origin != drag_hover_origin:
		drag_hover_origin = origin
		_show_preview(shape, origin)

func _finish_drag(position: Vector2) -> void:
	if drag_piece_index < 0:
		return
	var piece_index := drag_piece_index
	var was_dragging := drag_active
	var origin := _cell_at(position)
	drag_piece_index = -1
	drag_active = false
	drag_hover_origin = Vector2i(-1, -1)
	_clear_preview()
	if was_dragging and origin.x >= 0 and origin.y >= 0:
		host.set("selected_piece", piece_index)
		host.call("place_selected", origin)

func _show_preview(shape: Array, origin: Vector2i) -> void:
	_clear_preview()
	if origin.x < 0 or origin.y < 0:
		return
	var valid := bool(host.call("can_place", shape, origin))
	var preview_color := Color("10b981") if valid else Color("ef476f")
	var buttons: Variant = host.get("cell_buttons")
	if not buttons is Array:
		return
	for point in shape:
		var x := origin.x + int(point.x)
		var y := origin.y + int(point.y)
		if x < 0 or x >= 8 or y < 0 or y >= 8:
			continue
		var cell = buttons[y * 8 + x]
		cell.set("preview", true)
		cell.set("accent", preview_color)
		cell.queue_redraw()

func _clear_preview() -> void:
	var buttons: Variant = host.get("cell_buttons")
	if not buttons is Array:
		return
	for cell in buttons:
		if cell == null:
			continue
		cell.set("preview", false)
		cell.set("accent", Color("8b7cf6"))
		cell.queue_redraw()
