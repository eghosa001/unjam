extends Control

signal finished(level_number: int)
signal quit_requested

const GAME_ID := "water_sort"
const CAPACITY := 4

var level_number := 1
var daily_mode := false
var tubes: Array = []
var selected := -1
var moves := 0
var par_moves := 20
var color_count := 4
var history: Array = []
var board: GridContainer
var move_label: Label
var status_label: Label
var hint_label: Label
var title_label: Label
var meta_label: Label
var completed := false

func _ready() -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_ui()
	load_level()

func difficulty() -> String:
	return MultiGameManager.difficulty_for_level(level_number)

func level_config() -> Dictionary:
	var d := difficulty()
	var tier := mini(3, int((level_number - 1) / 2000))
	var colors := 4
	match d:
		"easy": colors = 4 + mini(1, tier)
		"medium": colors = 5 + mini(1, tier)
		"hard": colors = 6 + mini(2, tier)
		"milestone": colors = 7
		"boss": colors = 8
	var par := 18 + colors * 3
	if d == "hard": par += 6
	elif d == "milestone": par += 9
	elif d == "boss": par += 12
	return {"colors": clampi(colors, 4, 8), "par": par}

func style_box(color: Color, radius: int = 24, border: Color = Color.TRANSPARENT, border_width: int = 0, shadow: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	if border_width > 0:
		s.border_width_left = border_width
		s.border_width_right = border_width
		s.border_width_top = border_width
		s.border_width_bottom = border_width
		s.border_color = border
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.28)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, 7)
	return s

func style_button(button: Button, accent: bool = false) -> void:
	var base := Color("5da9ff") if accent else Color("1a3154")
	button.flat = false
	button.add_theme_stylebox_override("normal", style_box(Color(base, 0.92), 22, Color(1, 1, 1, 0.10), 1, 6))
	button.add_theme_stylebox_override("hover", style_box(base.lightened(0.08), 22, Color("67e8cf"), 2, 8))
	button.add_theme_stylebox_override("pressed", style_box(base.darkened(0.12), 22, Color.WHITE, 2, 2))
	button.add_theme_stylebox_override("disabled", style_box(Color("172238"), 22))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 20)

func build_ui() -> void:
	var bg := PremiumBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(Color("06111f"), Color("5da9ff"), MultiGameManager.world_for_level(level_number) - 1)
	add_child(bg)
	PremiumVisuals.set_accent(Color("5da9ff"))

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 38)
	outer.add_theme_constant_override("margin_right", 38)
	outer.add_theme_constant_override("margin_top", 44)
	outer.add_theme_constant_override("margin_bottom", 42)
	add_child(outer)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	outer.add_child(root)

	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", style_box(Color(0.025, 0.055, 0.105, 0.94), 28, Color(1, 1, 1, 0.08), 1, 10))
	root.add_child(header_panel)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 16)
	header_margin.add_theme_constant_override("margin_right", 16)
	header_margin.add_theme_constant_override("margin_top", 12)
	header_margin.add_theme_constant_override("margin_bottom", 12)
	header_panel.add_child(header_margin)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header_margin.add_child(header)
	var back := Button.new()
	back.text = "←  BACK"
	back.custom_minimum_size = Vector2(150, 68)
	style_button(back)
	back.pressed.connect(_quit)
	header.add_child(back)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color("f3fbff"))
	header.add_child(title_label)
	var retry := Button.new()
	retry.text = "RETRY"
	retry.custom_minimum_size = Vector2(140, 68)
	style_button(retry)
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	meta_label = Label.new()
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.add_theme_font_size_override("font_size", 18)
	meta_label.add_theme_color_override("font_color", Color("9eb2cc"))
	root.add_child(meta_label)

	var status_panel := PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", style_box(Color(0.02, 0.045, 0.09, 0.90), 24, Color("5da9ff66"), 2, 8))
	root.add_child(status_panel)
	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 20)
	status_margin.add_theme_constant_override("margin_right", 20)
	status_margin.add_theme_constant_override("margin_top", 12)
	status_margin.add_theme_constant_override("margin_bottom", 12)
	status_panel.add_child(status_margin)
	move_label = Label.new()
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.add_theme_font_size_override("font_size", 23)
	move_label.add_theme_color_override("font_color", Color("dbeafe"))
	status_margin.add_child(move_label)

	var board_panel := PanelContainer.new()
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_panel.add_theme_stylebox_override("panel", style_box(Color(0.012, 0.028, 0.058, 0.94), 38, Color("5da9ff55"), 2, 14))
	root.add_child(board_panel)
	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 18)
	board_margin.add_theme_constant_override("margin_right", 18)
	board_margin.add_theme_constant_override("margin_top", 22)
	board_margin.add_theme_constant_override("margin_bottom", 20)
	board_panel.add_child(board_margin)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_margin.add_child(center)
	board = GridContainer.new()
	board.columns = 5
	board.add_theme_constant_override("h_separation", 12)
	board.add_theme_constant_override("v_separation", 16)
	center.add_child(board)

	var action_panel := PanelContainer.new()
	action_panel.add_theme_stylebox_override("panel", style_box(Color(0.02, 0.045, 0.09, 0.90), 26, Color(1, 1, 1, 0.07), 1, 7))
	root.add_child(action_panel)
	var action_margin := MarginContainer.new()
	action_margin.add_theme_constant_override("margin_left", 18)
	action_margin.add_theme_constant_override("margin_right", 18)
	action_margin.add_theme_constant_override("margin_top", 12)
	action_margin.add_theme_constant_override("margin_bottom", 12)
	action_panel.add_child(action_margin)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	action_margin.add_child(actions)
	var undo := Button.new()
	undo.text = "↶  UNDO"
	undo.custom_minimum_size = Vector2(270, 76)
	style_button(undo)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.text = "✦  HINT"
	hint.custom_minimum_size = Vector2(270, 76)
	style_button(hint, true)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)

	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", Color("b9c8db"))
	hint_label.custom_minimum_size = Vector2(0, 38)
	root.add_child(hint_label)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 25)
	status_label.add_theme_color_override("font_color", Color("67e8cf"))
	status_label.custom_minimum_size = Vector2(0, 42)
	root.add_child(status_label)
	PremiumVisuals.entrance(root, 0.02)

func load_level() -> void:
	completed = false
	selected = -1
	moves = 0
	history.clear()
	status_label.text = ""
	hint_label.text = "Tap a tube, then tap where you want to pour"
	var config := level_config()
	color_count = int(config.get("colors", 4))
	par_moves = int(config.get("par", 20))
	title_label.text = "DAILY WATER SORT" if daily_mode else "WATER SORT  •  LEVEL %04d" % level_number
	meta_label.text = "%s  •  %s  •  WORLD %d" % [difficulty().to_upper(), MultiGameManager.world_name(GAME_ID, MultiGameManager.world_for_level(level_number)).to_upper(), MultiGameManager.world_for_level(level_number)]
	tubes = generate_tubes(level_number, color_count)
	_restore_checkpoint()
	render_board()
	AnalyticsManager.track("water_sort_level_started", {"level": level_number, "difficulty": difficulty(), "daily": daily_mode})

func generate_tubes(seed_value: int, colors: int) -> Array:
	var result: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + colors * 97
	var permutation: Array[int] = []
	for i in range(colors): permutation.append(i)
	for i in range(permutation.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := permutation[i]
		permutation[i] = permutation[j]
		permutation[j] = tmp
	var offset := rng.randi_range(1, maxi(1, colors - 1))
	for tube_index in range(colors):
		var tube: Array = []
		for layer in range(CAPACITY):
			var color_index := permutation[posmod(tube_index + layer * offset, colors)]
			tube.append(color_index)
		result.append(tube)
	result.append([])
	result.append([])
	return result

func render_board() -> void:
	if board == null: return
	for child in board.get_children(): child.queue_free()
	board.columns = 5 if tubes.size() <= 10 else 6
	var tube_width := 150.0 if tubes.size() <= 10 else 126.0
	var tube_height := 300.0 if tubes.size() <= 10 else 270.0
	for i in range(tubes.size()):
		var button := WaterTubeButton.new()
		button.custom_minimum_size = Vector2(tube_width, tube_height)
		button.tooltip_text = "Tube %d" % (i + 1)
		button.configure(tubes[i], i == selected, i)
		button.pressed.connect(select_tube.bind(i))
		board.add_child(button)
	move_label.text = "MOVES  %d    •    PERFECT ≤ %d    •    %d COLORS" % [moves, par_moves, color_count]

func select_tube(index: int) -> void:
	if completed: return
	hint_label.text = ""
	if selected < 0:
		if tubes[index].is_empty():
			status_label.text = "Choose a tube that contains color"
			return
		selected = index
		status_label.text = "Tube %d selected" % (index + 1)
		render_board()
		return
	if selected == index:
		selected = -1
		status_label.text = ""
		render_board()
		return
	if can_pour(selected, index):
		history.append({"tubes": tubes.duplicate(true), "moves": moves})
		pour(selected, index)
		moves += 1
		status_label.text = "Smooth pour"
		PremiumVisuals.screen_flash(Color("5da9ff"), 0.035)
	else:
		status_label.text = "That pour is not allowed"
	selected = -1
	render_board()
	_save_checkpoint()
	if is_complete(): complete_level()

func can_pour(from_idx: int, to_idx: int) -> bool:
	if from_idx < 0 or to_idx < 0 or from_idx >= tubes.size() or to_idx >= tubes.size(): return false
	var source: Array = tubes[from_idx]
	var target: Array = tubes[to_idx]
	if source.is_empty() or target.size() >= CAPACITY: return false
	return target.is_empty() or int(target.back()) == int(source.back())

func pour(from_idx: int, to_idx: int) -> void:
	var source: Array = tubes[from_idx]
	var target: Array = tubes[to_idx]
	var color := int(source.back())
	var same_count := 0
	for i in range(source.size() - 1, -1, -1):
		if int(source[i]) != color: break
		same_count += 1
	var amount := mini(same_count, CAPACITY - target.size())
	for _i in range(amount): target.append(source.pop_back())

func undo_move() -> void:
	if history.is_empty() or completed:
		status_label.text = "Nothing to undo"
		return
	var state: Dictionary = history.pop_back()
	tubes = state.get("tubes", []).duplicate(true)
	moves = int(state.get("moves", 0))
	selected = -1
	SaveManager.record_undo()
	status_label.text = "Move undone"
	render_board()
	_save_checkpoint()

func show_hint() -> void:
	if completed: return
	for from_idx in range(tubes.size()):
		if tubes[from_idx].is_empty(): continue
		for to_idx in range(tubes.size()):
			if from_idx == to_idx or not can_pour(from_idx, to_idx): continue
			if tubes[to_idx].is_empty() or int(tubes[to_idx].back()) == int(tubes[from_idx].back()):
				hint_label.text = "Try tube %d → tube %d" % [from_idx + 1, to_idx + 1]
				SaveManager.record_hint()
				return
	hint_label.text = "No legal move found — undo or retry"

func is_complete() -> bool:
	for tube in tubes:
		if tube.is_empty(): continue
		if tube.size() != CAPACITY: return false
		for value in tube:
			if int(value) != int(tube[0]): return false
	return true

func complete_level() -> void:
	if completed: return
	completed = true
	MultiGameManager.clear_checkpoint(GAME_ID)
	var stars := 3 if moves <= par_moves else (2 if moves <= par_moves + maxi(6, color_count) else 1)
	if daily_mode: MultiGameManager.complete_daily(GAME_ID, 100 + stars * 25)
	else: MultiGameManager.complete_level(GAME_ID, level_number, stars, 25 + color_count * 2)
	status_label.text = "LEVEL COMPLETE  •  %d ★" % stars
	PremiumVisuals.burst(Vector2(540, 880), Color("5da9ff"), 24)
	AnalyticsManager.track("water_sort_completed", {"level": level_number, "moves": moves, "stars": stars, "daily": daily_mode})
	await get_tree().create_timer(0.9).timeout
	finished.emit(-1 if daily_mode else level_number)

func restart_level() -> void:
	MultiGameManager.clear_checkpoint(GAME_ID)
	load_level()

func _save_checkpoint() -> void:
	if completed: return
	MultiGameManager.save_checkpoint(GAME_ID, {"level": level_number, "daily": daily_mode, "moves": moves, "tubes": tubes.duplicate(true), "history": history.duplicate(true)})

func _restore_checkpoint() -> void:
	var checkpoint := MultiGameManager.checkpoint(GAME_ID)
	if checkpoint.is_empty() or int(checkpoint.get("level", -1)) != level_number or bool(checkpoint.get("daily", false)) != daily_mode: return
	var saved_tubes = checkpoint.get("tubes", [])
	if saved_tubes is Array and not saved_tubes.is_empty():
		tubes = saved_tubes.duplicate(true)
		moves = maxi(0, int(checkpoint.get("moves", 0)))
		var saved_history = checkpoint.get("history", [])
		if saved_history is Array: history = saved_history.duplicate(true)

func _quit() -> void:
	_save_checkpoint()
	quit_requested.emit()
