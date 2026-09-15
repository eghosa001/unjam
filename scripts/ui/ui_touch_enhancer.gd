extends Node
class_name UiTouchEnhancer

# This helper now owns only sizing/readability. BlockPieceButton owns drag input.
# Keeping two independent drag handlers caused competing footprints and release
# placement on mobile, which made otherwise-correct dragging feel jittery.
var host: Control
var scan_elapsed := 0.0

func _ready() -> void:
	host = get_parent() as Control
	set_process(true)
	set_process_input(false)
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
	var is_back := label == "←" or label == "‹" or label == "BACK" or label.begins_with("← ") or label.contains("BACK HOME")
	if is_back:
		wanted = Vector2(maxf(wanted.x, 132.0), maxf(wanted.y, 88.0))
		button.add_theme_font_size_override("font_size", maxi(28, button.get_theme_font_size("font_size")))
	match host.name:
		"Game":
			if label == "BACK" or label == "RETRY": wanted = Vector2(160, 82)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(300, 92)
			elif label.contains("NEXT RESCUE") or label.contains("BACK HOME"): wanted = Vector2(520, 98)
			elif label.contains("DOUBLE BASE REWARD"): wanted = Vector2(520, 92)
		"WaterSort":
			if button is WaterTubeButton: wanted = Vector2(170, 330)
			elif is_back: wanted = Vector2(190, 92)
			elif label == "RETRY": wanted = Vector2(170, 82)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(270, 88)
		"BlockPuzzle":
			if _is_block_piece_button(button): wanted = Vector2(310, 150)
			elif is_back: wanted = Vector2(185, 92)
			elif label == "RETRY": wanted = Vector2(165, 82)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(290, 86)
		"Main":
			if label.begins_with("PLAY"): wanted = Vector2(270, 100)
			elif label == "CONTINUE": wanted = Vector2(270, 72)
			elif label.contains("DAILY REWARD") or label.ends_with("\nDONE"): wanted = Vector2(326, 110)
			elif label == "COLLECTION" or label == "SETTINGS": wanted = Vector2(326, 94)
			elif is_back: wanted = Vector2(136, 88)
			elif label.contains("PREV") or label == "CURRENT" or label.contains("NEXT"): wanted = Vector2(240, 76)
	if wanted.x > button.custom_minimum_size.x or wanted.y > button.custom_minimum_size.y:
		button.custom_minimum_size = Vector2(maxf(wanted.x, button.custom_minimum_size.x), maxf(wanted.y, button.custom_minimum_size.y))

func _is_block_piece_button(button: Button) -> bool:
	var script: Script = button.get_script() as Script
	if script == null:
		return false
	var path := String(script.resource_path)
	return path.ends_with("block_piece_button.gd") or path.ends_with("smooth_block_piece_button.gd")
