extends "res://scripts/game/rescue_rush_polished.gd"

const RescuePiece3D = preload("res://scripts/ui/rescue_piece_3d_button.gd")

# Presentation-only overhaul for Rescue Rush. Gameplay, level data, cascades,
# checkpoints, scoring and completion remain inherited from the polished game.

var rescue_title_label: Label
var difficulty_chip: Label
var world_subtitle_label: Label
var footer_label: Label
var _board_render_signature := 0
var _board_render_signature_valid := false

func style_button(button: Button, accent: bool = false) -> void:
	var base := Color("e7a72b") if accent else Color("183b70")
	var edge := Color("ffd166") if accent else Color("5da9ff")
	button.flat = false
	button.add_theme_stylebox_override("normal", style_box(Color(base, 0.96), 24, Color(edge, 0.54), 2))
	button.add_theme_stylebox_override("hover", style_box(base.lightened(0.08), 24, Color(edge, 0.92), 3))
	button.add_theme_stylebox_override("pressed", style_box(base.darkened(0.12), 24, Color.WHITE, 2))
	button.add_theme_stylebox_override("disabled", style_box(Color("172238"), 24, Color(1, 1, 1, 0.04), 1))
	button.add_theme_color_override("font_color", Color("f7fbff"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("6f7b91"))

func _panel_margin(left: int, right: int, top: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin

func _make_divider() -> ColorRect:
	var divider := ColorRect.new()
	divider.color = Color(1, 1, 1, 0.12)
	divider.custom_minimum_size = Vector2(2, 54)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return divider

func _status_label(alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", Color("eaf3ff"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.42))
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func build_ui() -> void:
	var world: int = int(level_data.get("world", 1))
	var backdrop := PremiumBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(Color("061224"), world_accent(), world - 1)
	add_child(backdrop)
	PremiumVisuals.set_accent(world_accent())
	PremiumVisuals.ambient_sparkles(18)

	var top_glow := ColorRect.new()
	top_glow.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_glow.custom_minimum_size = Vector2(0, 360)
	top_glow.color = Color(world_accent(), 0.055)
	top_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_glow)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 34)
	outer.add_theme_constant_override("margin_right", 34)
	outer.add_theme_constant_override("margin_top", 34)
	outer.add_theme_constant_override("margin_bottom", 28)
	add_child(outer)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 13)
	outer.add_child(root_box)

	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", style_box(Color(0.018, 0.045, 0.09, 0.94), 28, Color(1, 1, 1, 0.09), 1))
	root_box.add_child(header_panel)
	var header_margin := _panel_margin(15, 15, 11, 11)
	header_panel.add_child(header_margin)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header_margin.add_child(header)

	var back_button := Button.new()
	back_button.text = "←  BACK"
	back_button.custom_minimum_size = Vector2(288, 124)
	back_button.add_theme_font_size_override("font_size", 18)
	style_button(back_button)
	back_button.pressed.connect(_quit)
	header.add_child(back_button)

	var level_title := Label.new()
	level_title.text = "DAILY" if daily_mode else "LEVEL %04d" % level_number
	level_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_title.add_theme_font_size_override("font_size", 31)
	level_title.add_theme_color_override("font_color", Color("f5f9ff"))
	level_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.48))
	level_title.add_theme_constant_override("shadow_offset_y", 3)
	header.add_child(level_title)

	var retry := Button.new()
	retry.text = "↻  RETRY"
	retry.custom_minimum_size = Vector2(244, 120)
	retry.add_theme_font_size_override("font_size", 18)
	style_button(retry)
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	var brand_row := HBoxContainer.new()
	brand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	brand_row.add_theme_constant_override("separation", 14)
	root_box.add_child(brand_row)
	rescue_title_label = Label.new()
	rescue_title_label.text = "≡  RESCUE RUSH"
	rescue_title_label.add_theme_font_size_override("font_size", 38)
	rescue_title_label.add_theme_color_override("font_color", Color("eef7ff"))
	rescue_title_label.add_theme_color_override("font_shadow_color", Color(world_accent(), 0.38))
	rescue_title_label.add_theme_constant_override("shadow_offset_x", 2)
	rescue_title_label.add_theme_constant_override("shadow_offset_y", 3)
	brand_row.add_child(rescue_title_label)

	var chip_panel := PanelContainer.new()
	chip_panel.add_theme_stylebox_override("panel", style_box(Color("4a3515cc"), 18, Color("ffd166"), 2))
	brand_row.add_child(chip_panel)
	var chip_margin := _panel_margin(14, 14, 7, 7)
	chip_panel.add_child(chip_margin)
	difficulty_chip = Label.new()
	difficulty_chip.text = String(level_data.get("difficulty_label", "medium")).to_upper()
	difficulty_chip.add_theme_font_size_override("font_size", 16)
	difficulty_chip.add_theme_color_override("font_color", Color("ffd166"))
	chip_margin.add_child(difficulty_chip)

	world_subtitle_label = Label.new()
	world_subtitle_label.text = "%s  •  WORLD %d  •  FIND THE OPEN ESCAPE LANE" % [LevelManager.world_name(world).to_upper(), world]
	world_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_subtitle_label.add_theme_font_size_override("font_size", 16)
	world_subtitle_label.add_theme_color_override("font_color", Color("9eb3cf"))
	root_box.add_child(world_subtitle_label)

	var status_panel := PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", style_box(Color(0.018, 0.043, 0.085, 0.94), 28, Color(world_accent(), 0.38), 2))
	root_box.add_child(status_panel)
	var status_margin := _panel_margin(22, 22, 13, 13)
	status_panel.add_child(status_margin)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 18)
	status_margin.add_child(status)
	moves_label = _status_label(HORIZONTAL_ALIGNMENT_LEFT)
	status.add_child(moves_label)
	status.add_child(_make_divider())
	rescue_label = _status_label(HORIZONTAL_ALIGNMENT_CENTER)
	rescue_label.add_theme_color_override("font_color", Color("ffd166"))
	status.add_child(rescue_label)
	status.add_child(_make_divider())
	chain_label = _status_label(HORIZONTAL_ALIGNMENT_RIGHT)
	chain_label.add_theme_color_override("font_color", Color("67e8ff"))
	status.add_child(chain_label)

	var board_holder := CenterContainer.new()
	board_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(board_holder)
	board_panel = PanelContainer.new()
	board_panel.add_theme_stylebox_override("panel", style_box(Color(0.008, 0.024, 0.052, 0.975), 42, Color(world_accent(), 0.46), 3))
	board_holder.add_child(board_panel)
	var board_margin := _panel_margin(20, 20, 20, 20)
	board_panel.add_child(board_margin)
	board_grid = GridContainer.new()
	board_grid.columns = width
	board_grid.add_theme_constant_override("h_separation", 10)
	board_grid.add_theme_constant_override("v_separation", 10)
	board_margin.add_child(board_grid)

	var action_panel := PanelContainer.new()
	action_panel.add_theme_stylebox_override("panel", style_box(Color(0.018, 0.043, 0.085, 0.92), 28, Color(1, 1, 1, 0.07), 1))
	root_box.add_child(action_panel)
	var action_margin := _panel_margin(18, 18, 12, 12)
	action_panel.add_child(action_margin)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 20)
	action_margin.add_child(actions)
	var undo := Button.new()
	undo.text = "↶  UNDO"
	undo.custom_minimum_size = Vector2(250, 76)
	undo.add_theme_font_size_override("font_size", 22)
	style_button(undo)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.text = "✦  HINT"
	hint.custom_minimum_size = Vector2(250, 76)
	hint.add_theme_font_size_override("font_size", 22)
	style_button(hint, true)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)

	var tip_panel := PanelContainer.new()
	tip_panel.add_theme_stylebox_override("panel", style_box(Color(0.02, 0.05, 0.10, 0.84), 20, Color(1, 1, 1, 0.08), 1))
	root_box.add_child(tip_panel)
	var tip_margin := _panel_margin(16, 16, 9, 9)
	tip_panel.add_child(tip_margin)
	hint_label = Label.new()
	hint_label.text = "Tip: clear blockers and special pieces to open a lane for the rescue."
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 17)
	hint_label.add_theme_color_override("font_color", Color("b9c9dc"))
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.custom_minimum_size = Vector2(0, 42)
	tip_margin.add_child(hint_label)

	footer_label = Label.new()
	footer_label.text = "—  EVERY RESCUE COUNTS  ♥  —"
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_label.add_theme_font_size_override("font_size", 14)
	footer_label.add_theme_color_override("font_color", Color("67809f"))
	root_box.add_child(footer_label)

	PremiumVisuals.entrance(root_box, 0.025)
	_animate_brand()

func _animate_brand() -> void:
	if rescue_title_label == null:
		return
	var motion := get_node_or_null("/root/MotionSystem")
	if motion != null and bool(motion.call("reduced")):
		rescue_title_label.modulate.a = 1.0
		return
	rescue_title_label.modulate.a = 0.78
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(rescue_title_label, "modulate:a", 1.0, 0.32)
	# Settle at full opacity. The old infinite title pulse kept a tween alive for
	# the entire level even though it added no gameplay information.

func _direction_color(direction: String) -> Color:
	match direction:
		"up": return Color("2d9cff")
		"down": return Color("8b6df0")
		"left": return Color("3dcc78")
		_: return Color("ef5d68")

func _piece_visual_color(piece: Dictionary) -> Color:
	var type := String(piece.get("type", "normal"))
	match type:
		"rotate": return Color("8d67eb")
		"key": return Color("f0aa2c")
		"gate": return Color("64748b")
		"bomb": return Color("364158")
		"linked": return Color("8b5de7")
		"blocker": return Color("3b4658")
		_: return _direction_color(String(piece.get("direction", "right")))

func _best_escape_lane(piece_lookup: Dictionary = {}) -> Dictionary:
	var best_direction := Vector2i.UP
	var best_blockers := 999
	var best_cells: Array[Vector2i] = []
	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var cursor: Vector2i = rescue_pos + direction
		var blockers := 0
		var cells: Array[Vector2i] = []
		while is_inside(cursor):
			cells.append(cursor)
			var occupied := piece_lookup.has(cursor) if not piece_lookup.is_empty() else get_piece_index_at(cursor) >= 0
			if occupied:
				blockers += 1
			cursor += direction
		if blockers < best_blockers:
			best_blockers = blockers
			best_direction = direction
			best_cells = cells
	return {"direction": best_direction, "blockers": best_blockers, "cells": best_cells}

func _escape_arrow(direction: Vector2i) -> String:
	if direction == Vector2i.UP: return "↑"
	if direction == Vector2i.DOWN: return "↓"
	if direction == Vector2i.LEFT: return "←"
	return "→"

func _make_empty_cell(cell_size: int, pos: Vector2i, route: Dictionary) -> Control:
	var route_cells: Array = route.get("cells", [])
	var on_route := pos in route_cells
	var is_edge_exit := on_route and not is_inside(pos + Vector2i(route.get("direction", Vector2i.RIGHT)))
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(cell_size, cell_size)
	if on_route:
		var route_color := Color("51e28b") if int(route.get("blockers", 1)) == 0 else Color("3da9fc")
		slot.add_theme_stylebox_override("panel", style_box(Color(route_color, 0.10), 24, Color(route_color, 0.48 if is_edge_exit else 0.22), 2 if is_edge_exit else 1))
		if is_edge_exit:
			var exit_label := Label.new()
			exit_label.text = "EXIT\n" + _escape_arrow(Vector2i(route.get("direction", Vector2i.RIGHT)))
			exit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			exit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			exit_label.add_theme_font_size_override("font_size", maxi(16, int(cell_size * 0.17)))
			exit_label.add_theme_color_override("font_color", Color("8ff5b5"))
			exit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(exit_label)
			var pulse := create_tween().set_loops(1)
			pulse.tween_property(slot, "modulate", Color(1.08, 1.16, 1.10, 1), 0.40).set_trans(Tween.TRANS_CUBIC)
			pulse.tween_property(slot, "modulate", Color.WHITE, 0.40).set_trans(Tween.TRANS_CUBIC)
	else:
		slot.add_theme_stylebox_override("panel", style_box(Color(1, 1, 1, 0.022), 24, Color(1, 1, 1, 0.045), 1))
	return slot

func render_board() -> void:
	if board_grid == null:
		return

	moves_label.text = ("MOVES\n%d / %d" % [moves, action_budget]) if objective_type == "perfect_rescue" else "MOVES\n%d • 3★≤%d" % [moves, par_moves]
	var lives_text := "∞" if mistake_limit <= 0 else str(maxi(0, mistake_limit - mistakes_this_level))
	rescue_label.text = "LIVES\n%s" % lives_text
	chain_label.text = "CHAIN\n×%d" % maxi(chain_count, 1)

	# Some UI/navigation paths request a board refresh even when authoritative
	# gameplay state has not changed. Keep the existing controls in that case
	# instead of rebuilding every 3D piece, token, panel and signal connection.
	var board_signature := hash([level_number, daily_mode, width, height, rescue_pos, rescued, rescue_id, pieces])
	if _board_render_signature_valid and _board_render_signature == board_signature and board_grid.get_child_count() == width * height:
		return
	_board_render_signature = board_signature
	_board_render_signature_valid = true
	for child in board_grid.get_children():
		board_grid.remove_child(child)
		child.queue_free()

	var piece_lookup := {}
	for i in range(pieces.size()):
		var piece: Dictionary = pieces[i]
		if bool(piece.get("active", true)):
			piece_lookup[Vector2i(int(piece.get("x", -1)), int(piece.get("y", -1)))] = i
	var route := _best_escape_lane(piece_lookup)
	var viewport_width := get_viewport_rect().size.x
	var max_board_width := minf(viewport_width - 112.0, 860.0)
	var gap := 10.0 if width <= 5 else 7.0
	var calculated: float = floor((max_board_width - gap * float(width - 1)) / float(maxi(width, 1)))
	var cell_size := int(clampf(calculated, 82.0, 142.0))
	board_grid.columns = width
	board_grid.add_theme_constant_override("h_separation", int(gap))
	board_grid.add_theme_constant_override("v_separation", int(gap))

	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var piece_index := int(piece_lookup.get(pos, -1))
			if not rescued and pos == rescue_pos:
				var slot := PanelContainer.new()
				slot.custom_minimum_size = Vector2(cell_size, cell_size)
				slot.add_theme_stylebox_override("panel", style_box(Color("3e3216"), 28, Color("ffd166"), 3))
				var token := RescueToken.new()
				token.custom_minimum_size = Vector2(cell_size, cell_size)
				token.configure(rescue_id, Color("ffd166"))
				slot.add_child(token)
				board_grid.add_child(slot)
				_animate_cell(slot, x, y)
				var rescue_pulse := create_tween().set_loops(1)
				rescue_pulse.tween_property(slot, "modulate", Color(1.08, 1.04, 0.86, 1), 0.46).set_trans(Tween.TRANS_CUBIC)
				rescue_pulse.tween_property(slot, "modulate", Color.WHITE, 0.46).set_trans(Tween.TRANS_CUBIC)
			elif piece_index >= 0:
				var piece: Dictionary = pieces[piece_index]
				var button := RescuePiece3D.new()
				button.custom_minimum_size = Vector2(cell_size, cell_size)
				button.tooltip_text = String(piece.get("type", "normal")).capitalize()
				button.configure(String(piece.get("type", "normal")), String(piece.get("direction", "right")), _piece_visual_color(piece))
				button.disabled = String(piece.get("type", "normal")) in ["gate", "blocker"]
				if not button.disabled:
					button.pressed.connect(try_move.bind(piece_index))
				board_grid.add_child(button)
				_animate_cell(button, x, y)
			else:
				var empty := _make_empty_cell(cell_size, pos, route)
				board_grid.add_child(empty)
				_animate_cell(empty, x, y)

	if int(route.get("blockers", 1)) == 0 and not rescued:
		hint_label.text = "Escape lane open — free the rescue!"
		hint_label.add_theme_color_override("font_color", Color("8ff5b5"))
	else:
		hint_label.add_theme_color_override("font_color", Color("b9c9dc"))