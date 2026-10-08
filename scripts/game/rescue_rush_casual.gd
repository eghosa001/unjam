extends "res://scripts/game/rescue_rush_motion_final.gd"

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")
const GAMEPLAY_ART = preload("res://scripts/ui/unjam_gameplay_art.gd")
const RESCUE_SCREEN_OVERLAY: Texture2D = preload("res://assets/art/gameplay/rescue_screen_overlay.svg")


const NAVY := Color(0.03,0.23,0.47)
const OFF_WHITE := Color(1.0,0.995,0.97)
const GREEN := Color(0.13,0.78,0.39)
const BLUE := Color(0.03,0.43,0.78)
const ORANGE := Color(1.0,0.55,0.12)

var figma_canvas: FigmaReferenceCanvas
var board_backdrop_grid: GridContainer

func _compact_objective_instruction() -> String:
	match objective_type:
		"full_escape": return "WIN • CLEAR ALL ARROWS"
		"key_rescue": return "WIN • KEYS + CLEAR LANE"
		"gate_run": return "WIN • OPEN GATES + CLEAR LANE"
		"bomb_route": return "WIN • BOMBS + CLEAR LANE"
		"chain_rescue": return "WIN • LINKS + CLEAR LANE"
		"perfect_rescue": return "WIN • RESCUE ≤ %d MOVES" % action_budget
		_: return "WIN • OPEN ONE CLEAR LANE"

func _add_rescue_identity_emblem(canvas: Control) -> void:
	var emblem := PanelContainer.new()
	emblem.name = "Identity/Rescue Emblem"
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emblem.add_theme_stylebox_override("panel",RefCanvas.rounded_gradient3(Color("#6be28e"),Color("#21c763"),Color("#0d9545"),9,Color(0.73,1.0,0.82,0.55),1))
	RefCanvas.set_rect(emblem,77,17,30,30)
	canvas.add_child(emblem)
	var chick := PanelContainer.new()
	chick.name = "Mark/Chick"
	chick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chick.add_theme_stylebox_override("panel",RefCanvas.solid_box(Color("#ffd63d"),6,Color("#fff1a0"),1))
	RefCanvas.set_rect(chick,84,25,13,13)
	canvas.add_child(chick)
	var eye := ColorRect.new()
	eye.name = "Mark/Eye"
	eye.color = Color("#183b42")
	eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(eye,92,29,2,2)
	canvas.add_child(eye)
	var arrow := RefCanvas.label("↗",11,Color.WHITE,true)
	arrow.name = "Mark/Arrow"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(arrow,94,18,11,11)
	canvas.add_child(arrow)

func style_button(button: Button, accent: bool = false) -> void:
	var fill := ORANGE if accent else BLUE
	button.add_theme_stylebox_override("normal", RefCanvas.rounded_gradient3(fill.lightened(0.18), fill, fill.darkened(0.18), 16, fill.lightened(0.30), 1.3))
	button.add_theme_stylebox_override("hover", RefCanvas.rounded_gradient3(fill.lightened(0.24), fill.lightened(0.05), fill.darkened(0.13), 16, fill.lightened(0.38), 1.3))
	button.add_theme_stylebox_override("pressed", RefCanvas.rounded_gradient3(fill, fill.darkened(0.08), fill.darkened(0.25), 16, fill.lightened(0.20), 1.3))
	button.add_theme_color_override("font_color", OFF_WHITE)
	button.add_theme_color_override("font_hover_color", OFF_WHITE)
	button.add_theme_color_override("font_pressed_color", OFF_WHITE)

func restart_level() -> void:
	var enhancer := get_node_or_null("UiTouchEnhancer")
	if enhancer != null and enhancer.get_parent() == self:
		remove_child(enhancer)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	super.restart_level()
	if enhancer != null and is_instance_valid(enhancer):
		add_child(enhancer)

func build_ui() -> void:
	clip_contents = true
	PremiumVisuals.set_accent(GREEN)
	var bg := ColorRect.new()
	bg.name = "RescueFigmaViewportBackground"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.10,0.30,0.22)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	figma_canvas = RefCanvas.new()
	figma_canvas.name = "FigmaRescue390x844"
	add_child(figma_canvas)
	_build_figma_rescue(figma_canvas)
	call_deferred("apply_theme_mode", _shell_dark_mode())

func _build_figma_rescue(canvas: Control) -> void:
	var sky := PanelContainer.new()
	sky.name = "RescueScenicSky"
	# One continuous material from header to footer. The former opaque "ground"
	# rectangle started at y=43 and ended at y=484, leaving two obvious horizontal
	# seams across the rendered phone surface.
	sky.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#a9c4b9"), Color("#789477"), Color("#365648"), 34, Color("#aebeb4"), 1, 0.34))
	RefCanvas.set_rect(sky, -15.9, -58.12, 419.81, 908.51)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(sky)
	var platform := Polygon2D.new()
	platform.name = "RescuePerspectivePlatform"
	platform.polygon = PackedVector2Array([Vector2(22,481),Vector2(368,481),Vector2(340,147),Vector2(50,147)])
	platform.color = Color(0.55,0.66,0.53,0.42)
	canvas.add_child(platform)
	var scenic_overlay := TextureRect.new()
	scenic_overlay.name = "RescueAuthoredScreenWorld"
	scenic_overlay.texture = RESCUE_SCREEN_OVERLAY
	scenic_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scenic_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	scenic_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(scenic_overlay, 0, 0, 390, 844)
	canvas.add_child(scenic_overlay)

	RefCanvas.add_shadow(canvas, Rect2(15,15,54,54), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var back := RefCanvas.premium_button("←",22,NAVY,Color(0.97,1.0,0.96),16,Color(0.67,0.90,0.72,0.55),1.4)
	back.name = "RescueBackAction"
	back.tooltip_text = "Back to levels"
	back.accessibility_name = "Back to level selection"
	RefCanvas.set_rect(back,15,15,54,54)
	back.pressed.connect(_quit)
	canvas.add_child(back)
	RefCanvas.add_shadow(canvas, Rect2(319,15,54,54), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var retry := RefCanvas.premium_button("↻",23,Color("#088c3d"),Color(0.97,1.0,0.96),16,Color(0.67,0.90,0.72,0.55),1.4)
	retry.name = "RescueRetryAction"
	retry.tooltip_text = "Restart level"
	retry.accessibility_name = "Restart current puzzle"
	RefCanvas.set_rect(retry,319,15,54,54)
	retry.pressed.connect(restart_level)
	canvas.add_child(retry)
	_add_rescue_identity_emblem(canvas)
	var title := RefCanvas.label("RESCUE RUSH",20,OFF_WHITE,true)
	title.name = "RescueGameplayTitle"
	RefCanvas.style_display_title(title, Color("#67f2a1"), Color("#06452c"), 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(title,115,15,184,25)
	RefCanvas.fit_single_line_text(title,180.0,20,15)
	RefCanvas.set_rect(title,115,15,184,25)
	canvas.add_child(title)
	var world := int(level_data.get("world", 1))
	var subtitle := RefCanvas.label("LEVEL %d • WORLD %d" % [level_number,world],14,Color(0.92,0.98,1.0),true)
	subtitle.name = "RescueGameplayMeta"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.clip_text = true
	RefCanvas.set_rect(subtitle,115,47,184,16)
	RefCanvas.fit_single_line_text(subtitle,180.0,14,12)
	RefCanvas.set_rect(subtitle,115,47,184,16)
	canvas.add_child(subtitle)

	var status_panel := PanelContainer.new()
	status_panel.name = "CompactStatusStrip"
	RefCanvas.add_shadow(canvas, Rect2(17,81,354,48), 15, Color(0.02,0.10,0.18,0.22), 5, Vector2(0,4))
	status_panel.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color(0.18,0.37,0.30,0.52),Color(0.12,0.30,0.25,0.48),Color(0.08,0.22,0.20,0.46),15,Color(0.55,0.92,0.66,0.12),1.0,0.12))
	RefCanvas.set_rect(status_panel,17,81,354,48)
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(status_panel)
	moves_label = _status_label(HORIZONTAL_ALIGNMENT_LEFT)
	rescue_label = _status_label(HORIZONTAL_ALIGNMENT_CENTER)
	chain_label = _status_label(HORIZONTAL_ALIGNMENT_RIGHT)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation",4)
	RefCanvas.set_rect(status_row,27,81,334,48)
	canvas.add_child(status_row)
	for label in [moves_label,rescue_label,chain_label]:
		label.add_theme_font_size_override("font_size",16)
		label.add_theme_color_override("font_color",OFF_WHITE)
		status_row.add_child(label)

	var objective := PanelContainer.new()
	objective.name = "RescueObjectiveCard"
	RefCanvas.add_shadow(canvas, Rect2(17,137,354,34), 12, Color(0.02,0.10,0.18,0.14), 3, Vector2(0,3))
	objective.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#173d31"),Color("#123429"),Color("#0c2b24"),12,Color(0.55,0.96,0.67,0.16),1.0,0.12))
	RefCanvas.set_rect(objective,17,137,354,34)
	objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(objective)
	var objective_label := RefCanvas.label(_compact_objective_instruction(),16,Color("#b9ffd0"),true)
	objective_label.name = "RescueObjectiveLabel"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.accessibility_name = objective_instruction()
	objective_label.tooltip_text = objective_instruction()
	objective_label.clip_text = true
	RefCanvas.set_rect(objective_label,29,137,330,34)
	RefCanvas.fit_single_line_text(objective_label,320.0,16,13)
	RefCanvas.set_rect(objective_label,29,137,330,34)
	canvas.add_child(objective_label)

	var depth := PanelContainer.new()
	depth.name = "RescueBoardDepth"
	depth.add_theme_stylebox_override("panel",RefCanvas.solid_box(Color(0.02,0.11,0.10,0.16),26))
	RefCanvas.set_rect(depth,23,194,344,344)
	canvas.add_child(depth)
	board_panel = PanelContainer.new()
	board_panel.name = "RescueBoardPanel"
	board_panel.add_theme_stylebox_override("panel",RefCanvas.rounded_gradient3(Color("#1b5840"),Color("#124632"),Color("#0b3528"),26,Color(0.62,0.96,0.72,0.10),1,0.10))
	RefCanvas.set_rect(board_panel,21,180,348,348)
	canvas.add_child(board_panel)
	var board_art := GAMEPLAY_ART.new()
	board_art.name = "RescueBoardWorldArt"
	board_art.configure("rescue_board", GREEN, _shell_dark_mode(), level_number)
	board_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_panel.add_child(board_art)

	# A persistent lattice sits below pieces and route highlights. Every board
	# coordinate is visible at a glance, including occupied cells, so players can
	# read position/direction without guessing against the scenic illustration.
	var backdrop_margin := MarginContainer.new()
	backdrop_margin.name = "RescueBoardBackdropMargin"
	backdrop_margin.z_index = 1
	backdrop_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left","right","top","bottom"]:
		backdrop_margin.add_theme_constant_override("margin_%s" % side,10)
	board_panel.add_child(backdrop_margin)
	board_backdrop_grid = GridContainer.new()
	board_backdrop_grid.name = "RescueBoardBackdropGrid"
	board_backdrop_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop_margin.add_child(board_backdrop_grid)
	_rebuild_rescue_grid_backdrop(_shell_dark_mode())

	var margin := MarginContainer.new()
	margin.z_index = 2
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_%s" % side,10)
	board_panel.add_child(margin)
	board_grid = GridContainer.new()
	board_grid.name = "RescueBoardGrid"
	board_grid.columns = width
	board_grid.add_theme_constant_override("h_separation",5)
	board_grid.add_theme_constant_override("v_separation",5)
	margin.add_child(board_grid)

	var actions := HBoxContainer.new()
	actions.name = "CompactGameActions"
	actions.add_theme_constant_override("separation",14)
	RefCanvas.set_rect(actions,21,566,346,62)
	canvas.add_child(actions)
	var undo := _action("↶  UNDO",GREEN)
	undo.name = "RescueUndoAction"
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := _action("HINT",GREEN)
	hint.name = "RescueHintAction"
	# HintManager keeps the cost visible; Rescue's compact 60px control needs it
	# anchored in the upper-right rather than sitting on the lower bevel.
	hint.set_meta("unjam_hint_badge_top_right", true)
	actions.add_child(hint)
	var restart := _action("↻  RESTART",GREEN)
	restart.name = "RescueRestartAction"
	restart.pressed.connect(restart_level)
	actions.add_child(restart)

	# Use the lower playfield intentionally instead of leaving a large inactive
	# band below the controls. Guidance remains contextual and never competes
	# with the board; the final ~84px are kept clear for visual/system breathing room.
	RefCanvas.add_shadow(canvas, Rect2(21,640,346,120), 18, Color(0.02,0.10,0.18,0.18), 4, Vector2(0,4))
	var guidance_panel := PanelContainer.new()
	guidance_panel.name = "RescueGuidanceCard"
	guidance_panel.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color(0.10,0.28,0.22,0.70),Color(0.08,0.23,0.19,0.68),Color(0.05,0.18,0.16,0.66),18,Color(0.55,0.96,0.67,0.12),1.0,0.12))
	RefCanvas.set_rect(guidance_panel,21,640,346,120)
	guidance_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(guidance_panel)

	hint_label = RefCanvas.label("Tap a clear arrow • follow the grid to the open edge.",15,OFF_WHITE,true)
	hint_label.name = "RescueGuidanceText"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	RefCanvas.set_rect(hint_label,39,650,310,98)
	canvas.add_child(hint_label)

	var frame_border := PanelContainer.new()
	frame_border.name = "RescueFrameBorder"
	frame_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_border.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color.TRANSPARENT, 34, Color("#b8d1e0"), 1))
	RefCanvas.set_rect(frame_border, 0, 0, 390, 844)
	frame_border.z_index = 900
	canvas.add_child(frame_border)

func _rescue_grid_slot_style(dark: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06,0.23,0.17,0.34) if dark else Color(0.86,1.0,0.90,0.22)
	style.border_color = Color(0.58,0.96,0.70,0.24) if dark else Color(0.13,0.48,0.30,0.22)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func _rebuild_rescue_grid_backdrop(dark: bool) -> void:
	if board_backdrop_grid == null or not is_instance_valid(board_backdrop_grid):
		return
	for child in board_backdrop_grid.get_children():
		board_backdrop_grid.remove_child(child)
		child.queue_free()
	board_backdrop_grid.columns = width
	var gap := _figma_board_gap()
	board_backdrop_grid.add_theme_constant_override("h_separation", gap)
	board_backdrop_grid.add_theme_constant_override("v_separation", gap)
	var cell_size := _figma_board_cell_size()
	for y in range(height):
		for x in range(width):
			var cell := PanelContainer.new()
			cell.name = "RescueGridSlot_%d_%d" % [x,y]
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.custom_minimum_size = Vector2(cell_size,cell_size)
			cell.add_theme_stylebox_override("panel", _rescue_grid_slot_style(dark))
			board_backdrop_grid.add_child(cell)

func _action(text_value: String, _fill: Color) -> Button:
	var fill := Color("#183d31")
	var border := Color(0.45,0.90,0.58,0.18)
	var result := RefCanvas.premium_button(text_value,15,OFF_WHITE,fill,16,border,1.0)
	result.custom_minimum_size = Vector2(106,60)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result

func _figma_board_gap() -> int:
	var span := maxi(width, height)
	if span <= 5:
		return 6
	if span <= 7:
		return 5
	# 8x8 boss/finale boards gain two pixels per cell versus the former 5px
	# spacing while preserving the same 348x348 audited play area.
	return 3

func _figma_board_cell_size() -> int:
	if width <= 5 and height <= 5:
		return 58
	var available := 328.0
	var gap := _figma_board_gap()
	var span := maxi(width, height)
	return int(clampf(floor((available - float(gap * maxi(span - 1,0))) / float(maxi(span,1))),30.0,43.0))

func _make_empty_cell(_cell_size: int, pos: Vector2i, route: Dictionary) -> Control:
	var slot := super._make_empty_cell(_figma_board_cell_size(), pos, route)
	var route_cells: Array = route.get("cells", [])
	var on_route := pos in route_cells
	var is_edge_exit := on_route and not is_inside(pos + Vector2i(route.get("direction", Vector2i.RIGHT)))
	var well_style := StyleBoxFlat.new()
	well_style.corner_radius_top_left = 9
	well_style.corner_radius_top_right = 9
	well_style.corner_radius_bottom_left = 9
	well_style.corner_radius_bottom_right = 9

	if on_route:
		# The playable route is a luminous lane; everything else intentionally recedes.
		var open_lane := int(route.get("blockers",1)) == 0
		well_style.bg_color = Color("#45e781", 0.12 if open_lane else 0.055)
		well_style.border_color = Color("#8ff5b5", 0.72 if is_edge_exit else 0.10)
		var bw := 2 if is_edge_exit else 1
		well_style.border_width_left = bw
		well_style.border_width_right = bw
		well_style.border_width_top = bw
		well_style.border_width_bottom = bw
	else:
		well_style.bg_color = Color(0.86,1.0,0.90,0.008)
		well_style.border_color = Color.TRANSPARENT
		well_style.border_width_left = 0
		well_style.border_width_right = 0
		well_style.border_width_top = 0
		well_style.border_width_bottom = 0

	slot.add_theme_stylebox_override("panel", well_style)
	for child in slot.get_children():
		if child is Label:
			var label := child as Label
			if "EXIT" in label.text:
				label.text = _escape_arrow(Vector2i(route.get("direction",Vector2i.RIGHT)))
				label.add_theme_font_size_override("font_size",24)
				label.add_theme_color_override("font_color",Color("#b7ffd0"))
				label.custom_minimum_size = Vector2.ZERO
	return slot

func _fit_board_to_viewport() -> void:
	if board_grid == null or board_panel == null:
		return
	board_grid.columns = width
	var gap := _figma_board_gap()
	board_grid.add_theme_constant_override("h_separation",gap)
	board_grid.add_theme_constant_override("v_separation",gap)
	var cell_size := _figma_board_cell_size()

	if board_backdrop_grid != null and is_instance_valid(board_backdrop_grid):
		if board_backdrop_grid.get_child_count() != width * height:
			_rebuild_rescue_grid_backdrop(_shell_dark_mode())
		board_backdrop_grid.columns = width
		board_backdrop_grid.add_theme_constant_override("h_separation",gap)
		board_backdrop_grid.add_theme_constant_override("v_separation",gap)
		for cell in board_backdrop_grid.get_children():
			if cell is Control:
				(cell as Control).custom_minimum_size = Vector2(cell_size,cell_size)

	for child in board_grid.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(cell_size,cell_size)
			if child is PanelContainer:
				var cell_panel := child as PanelContainer
				var authored_style := cell_panel.get_theme_stylebox("panel")
				if authored_style != null:
					var exact_style := authored_style.duplicate() as StyleBox
					for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
						exact_style.set_content_margin(side,0.0)
					cell_panel.add_theme_stylebox_override("panel",exact_style)
			if child.get_child_count() > 0 and child.get_child(0) is Control:
				(child.get_child(0) as Control).custom_minimum_size = Vector2(cell_size,cell_size)
	board_panel.custom_minimum_size = Vector2(348,348)
	board_panel.size = Vector2(348,348)

func _hint_arrow_index() -> int:
	var solver_index := PuzzleSolver.first_solution_move(level_data, pieces, 6000)
	if solver_index >= 0 and solver_index < pieces.size():
		var solver_piece: Dictionary = pieces[solver_index]
		if bool(solver_piece.get("active", true)) and String(solver_piece.get("type", "normal")) not in ["gate", "blocker"] and is_path_clear(solver_index):
			return solver_index
	for i in range(pieces.size()):
		var piece: Dictionary = pieces[i]
		if not bool(piece.get("active", true)):
			continue
		if String(piece.get("type", "normal")) in ["gate", "blocker"]:
			continue
		if is_path_clear(i):
			return i
	return -1

func show_hint() -> void:
	if board_locked or rescued:
		return
	var index := _hint_arrow_index()
	if index < 0:
		hint_label.text = "No arrow can be safely removed from this position."
		FeedbackManager.blocked()
		return
	hints_used_this_level += 1
	SaveManager.record_hint()
	FeedbackManager.tap()
	AnalyticsManager.hint_used(level_number)
	var legal_before := _legal_map()
	history.append(snapshot())
	board_locked = true
	chain_count = maxi(1, chain_count)
	FeedbackManager.escape(chain_count)
	escape_piece(index, true)
	await get_tree().create_timer(0.06).timeout
	await _resolve_cascades(legal_before)
	await resolve_rescue()
	if not is_inside_tree():
		return
	if not rescued:
		render_board()
		hint_label.text = "Hint cleared one arrow."
		_save_checkpoint()
	board_locked = false

func render_board() -> void:
	super.render_board()
	if moves_label != null:
		var lives_text := "∞" if mistake_limit <= 0 else str(maxi(0, mistake_limit - mistakes_this_level))
		# Keep the actual survival state legible on an 8×8 board. Previously a
		# combo string was appended to the same narrow 334px HUD line, making
		# long late-game progress unreadable.
		moves_label.visible = true
		if objective_type == "perfect_rescue":
			moves_label.text = "MOVES %d/%d   •   LIVES %s" % [moves, action_budget, lives_text]
		else:
			moves_label.text = "MOVES %d   •   LIVES %s" % [moves, lives_text]
		moves_label.tooltip_text = "Moves %d, 3 stars at %d moves, remaining lives %s" % [moves, par_moves, lives_text]
		moves_label.accessibility_name = moves_label.tooltip_text
		moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		moves_label.add_theme_font_size_override("font_size",16)
	if rescue_label != null:
		rescue_label.visible = false
	if chain_label != null:
		chain_label.visible = chain_count > 1
		if chain_count > 1:
			chain_label.text = "COMBO ×%d" % chain_count
			chain_label.tooltip_text = "Current combo chain %d" % chain_count
			chain_label.accessibility_name = chain_label.tooltip_text
			chain_label.add_theme_font_size_override("font_size",15)
	var objective_label := find_child("RescueObjectiveLabel",true,false) as Label
	if objective_label != null:
		objective_label.accessibility_name = objective_instruction()
		objective_label.tooltip_text = objective_instruction()

func _shell_dark_mode() -> bool:
	var main := get_tree().current_scene
	var shell := main.get_node_or_null("UXShell") if main != null else null
	return shell != null and String(shell.get("theme_mode")) == "dark"

func _style_rescue_button(button: Button, dark: bool, accent: Color = GREEN, compact_header: bool = false) -> void:
	if button == null or not is_instance_valid(button):
		return
	var fill := Color("#182a22") if dark else (Color(0.97,1.0,0.96) if compact_header else Color("#365448"))
	var text := Color("#eafbf0") if dark else (Color("#088c3d") if compact_header else OFF_WHITE)
	var border := Color(accent, 0.72 if dark else 0.52)
	button.add_theme_stylebox_override("normal", RefCanvas.rounded_gradient3(fill.lightened(0.08 if dark else 0.02), fill, fill.darkened(0.12 if dark else 0.05), 16, border, 1.2))
	button.add_theme_stylebox_override("hover", RefCanvas.rounded_gradient3(fill.lightened(0.14), fill.lightened(0.04), fill.darkened(0.08), 16, border.lightened(0.10), 1.2))
	button.add_theme_stylebox_override("pressed", RefCanvas.rounded_gradient3(fill, fill.darkened(0.08), fill.darkened(0.18), 16, border, 1.2))
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(key, text)

func apply_theme_mode(dark: bool) -> void:
	var bg := find_child("RescueFigmaViewportBackground", true, false) as ColorRect
	if bg != null:
		bg.color = Color("#101a16") if dark else Color(0.10,0.30,0.22)
	var sky := find_child("RescueScenicSky", true, false) as PanelContainer
	if sky != null:
		sky.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
			Color("#1c2823") if dark else Color("#a9c4b9"),
			Color("#20382d") if dark else Color("#789477"),
			Color("#102219") if dark else Color("#365648"),
			34, Color("#4d6258") if dark else Color("#aebeb4"), 1, 0.34
		))
	var platform := find_child("RescuePerspectivePlatform", true, false) as Polygon2D
	if platform != null:
		platform.color = Color(0.18,0.29,0.22,0.52) if dark else Color(0.55,0.66,0.53,0.42)
	var status_panel := find_child("CompactStatusStrip", true, false) as PanelContainer
	if status_panel != null:
		status_panel.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
			Color("#20372e") if dark else Color("#365448"),
			Color("#192e26") if dark else Color("#29483d"),
			Color("#11221b") if dark else Color("#20392f"),
			15, Color(0.49,0.72,0.56,0.44), 1.1, 0.24
		))
	var objective := find_child("RescueObjectiveCard", true, false) as PanelContainer
	if objective != null:
		objective.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
			Color("#213229") if dark else Color("#fffdf7"),
			Color("#1b2a22") if dark else Color("#faf7ef"),
			Color("#152119") if dark else Color("#f1ede2"),
			12, Color(0.55,0.76,0.61,0.48 if dark else 0.32), 1.0, 0.22
		))
	var objective_label := find_child("RescueObjectiveLabel", true, false) as Label
	if objective_label != null:
		objective_label.add_theme_color_override("font_color", Color("#dff8e8") if dark else Color("#088c3d"))
	var depth := find_child("RescueBoardDepth", true, false) as PanelContainer
	if depth != null:
		depth.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
			Color("#172a2d") if dark else Color("#335257"),
			Color("#102328") if dark else Color("#25434b"),
			Color("#0a1a20") if dark else Color("#1a3340"), 26
		))
	if board_panel != null:
		board_panel.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
			Color("#28483c") if dark else Color("#d1ebc2"),
			Color("#1e392f") if dark else Color("#99c4ab"),
			Color("#152b25") if dark else Color("#5e8c85"),
			26, Color(0.46,0.78,0.58,0.72) if dark else Color(0.94,1.0,0.88,0.72), 2, 0.45
		))
	if board_backdrop_grid != null and is_instance_valid(board_backdrop_grid):
		for cell in board_backdrop_grid.get_children():
			if cell is PanelContainer:
				(cell as PanelContainer).add_theme_stylebox_override("panel", _rescue_grid_slot_style(dark))
	for label in [moves_label, rescue_label, chain_label]:
		if label != null:
			label.add_theme_color_override("font_color", Color("#eafbf0") if dark else OFF_WHITE)
	if hint_label != null:
		hint_label.add_theme_color_override("font_color", Color("#bdeecb") if dark else NAVY)
	_style_rescue_button(find_child("RescueBackAction", true, false) as Button, dark, GREEN, true)
	_style_rescue_button(find_child("RescueRetryAction", true, false) as Button, dark, GREEN, true)
	for name in ["RescueUndoAction", "RescueHintAction", "RescueRestartAction"]:
		_style_rescue_button(find_child(name, true, false) as Button, dark, GREEN, false)
	var frame := find_child("RescueFrameBorder", true, false) as PanelContainer
	if frame != null:
		frame.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color.TRANSPARENT, 34, Color("#4c685b") if dark else Color("#b8d1e0"), 1))
