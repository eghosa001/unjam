extends Node
class_name UiTouchEnhancer

# This helper now owns only sizing/readability. BlockPieceButton owns drag input.
# Keeping two independent drag handlers caused competing footprints and release
# placement on mobile, which made otherwise-correct dragging feel jittery.
var host: Control
var refresh_pending := false

func _ready() -> void:
	host = get_parent() as Control
	set_process_input(false)
	get_tree().node_added.connect(_on_node_added)
	_queue_enhancements()

func _on_node_added(node: Node) -> void:
	if host == null or not is_instance_valid(host) or node == host:
		return
	if not host.is_ancestor_of(node):
		return
	# node_added fires for each control entering the live subtree. Apply the only
	# per-node rule directly instead of recursively rescanning the entire screen
	# every time gameplay spawns a ghost, effect, label or button.
	if node is Button:
		_apply_button_size(node as Button)

func _queue_enhancements() -> void:
	if refresh_pending:
		return
	refresh_pending = true
	call_deferred("_flush_enhancements")

func _flush_enhancements() -> void:
	refresh_pending = false
	_apply_enhancements()

func _apply_enhancements() -> void:
	if host == null or not is_instance_valid(host):
		return
	_enlarge_buttons(host)
	if host.find_child("FigmaWater390x844", true, false) != null or host.find_child("FigmaBlock390x844", true, false) != null or host.find_child("FigmaRescue390x844", true, false) != null:
		return
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
	if node != host and node.has_meta("unjam_figma_reference_root"):
		return
	# A nested surface with its own enhancer owns all sizing below that root.
	# This keeps Main from re-sizing an active game scene a second time.
	if node != host and node.get_node_or_null("UiTouchEnhancer") != null:
		return
	for child in node.get_children():
		if child is Button:
			_apply_button_size(child)
		_enlarge_buttons(child)

func _apply_button_size(button: Button) -> void:
	if button.has_meta("unjam_figma_exact_geometry"):
		return
	# Gameplay drawing controls are not ordinary buttons. Enforcing navigation
	# touch-target sizes on them can blow up an 8x8 board, distort bottles, or
	# resize Rescue Rush board pieces when Main scans an active game subtree.
	if _is_block_cell_button(button) or _is_water_tube_widget(button) or _is_rescue_piece_button(button):
		return
	var label := button.text.strip_edges().to_upper()
	var wanted := Vector2(maxf(button.custom_minimum_size.x, 160.0), maxf(button.custom_minimum_size.y, 108.0))
	var is_back := label == "←" or label == "‹" or label == "BACK" or label.begins_with("← ") or label.contains("BACK HOME")
	if is_back:
		wanted = Vector2(maxf(wanted.x, 288.0), maxf(wanted.y, 124.0))
		button.add_theme_font_size_override("font_size", maxi(30, button.get_theme_font_size("font_size")))
	match host.name:
		"Game":
			if label == "BACK" or label == "RETRY": wanted = Vector2(288, 124)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(350, 116)
			elif label.contains("NEXT RESCUE") or label.contains("BACK HOME"): wanted = Vector2(540, 108)
			elif label.contains("DOUBLE BASE REWARD"): wanted = Vector2(540, 104)
		"WaterSort":
			if button is WaterTubeButton: wanted = Vector2(170, 330)
			elif is_back: wanted = Vector2(288, 124)
			elif label == "RETRY" or label.contains("RETRY"): wanted = Vector2(244, 120)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(350, 116)
		"BlockPuzzle":
			if _is_block_piece_button(button): wanted = Vector2(310, 150)
			elif is_back: wanted = Vector2(288, 124)
			elif label == "RETRY" or label.contains("RETRY"): wanted = Vector2(244, 120)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(350, 116)
		"Main":
			if label.begins_with("PLAY"): wanted = Vector2(270, 100)
			elif label == "CONTINUE": wanted = Vector2(270, 72)
			elif label.contains("DAILY REWARD") or label.ends_with("\nDONE"): wanted = Vector2(326, 110)
			elif label == "COLLECTION" or label == "SETTINGS": wanted = Vector2(326, 94)
			elif is_back: wanted = Vector2(288, 124)
			elif label.contains("PREV") or label == "CURRENT" or label.contains("NEXT"): wanted = Vector2(250, 96)
	if wanted.x > button.custom_minimum_size.x or wanted.y > button.custom_minimum_size.y:
		button.custom_minimum_size = Vector2(maxf(wanted.x, button.custom_minimum_size.x), maxf(wanted.y, button.custom_minimum_size.y))

func _is_block_piece_button(button: Button) -> bool:
	var script: Script = button.get_script() as Script
	if script == null:
		return false
	var path := String(script.resource_path)
	return path.ends_with("block_piece_button.gd") or path.ends_with("smooth_block_piece_button.gd")

func _button_script_path(button: Button) -> String:
	var script := button.get_script() as Script
	return String(script.resource_path) if script != null else ""

func _is_block_cell_button(button: Button) -> bool:
	return _button_script_path(button).contains("block_cell_button.gd")

func _is_water_tube_widget(button: Button) -> bool:
	return _button_script_path(button).contains("water_tube")

func _is_rescue_piece_button(button: Button) -> bool:
	return _button_script_path(button).contains("rescue_piece_3d_button.gd")
