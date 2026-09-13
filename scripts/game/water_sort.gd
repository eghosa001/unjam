extends Control

signal finished(level_number: int)
signal quit_requested

const GAME_ID := "water_sort"
const CAPACITY := 4
const SYMBOLS := ["●", "◆", "■", "▲", "★", "⬟", "♥", "✦"]
const PALETTE := ["ff6b7a", "5da9ff", "ffd166", "57d69a", "c074ff", "ff9d57", "67e8cf", "f472b6"]

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
var completed := false

func _ready() -> void:
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

func build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := PremiumBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(Color("071426"), Color("5da9ff"), MultiGameManager.world_for_level(level_number) - 1)
	add_child(bg)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right"]:
		outer.add_theme_constant_override(side, 42)
	outer.add_theme_constant_override("margin_top", 52)
	outer.add_theme_constant_override("margin_bottom", 52)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	outer.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(140, 70)
	back.pressed.connect(_quit)
	header.add_child(back)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	header.add_child(title_label)
	var retry := Button.new()
	retry.text = "RETRY"
	retry.custom_minimum_size = Vector2(140, 70)
	retry.pressed.connect(restart_level)
	header.add_child(retry)
	var meta := Label.new()
	meta.name = "Meta"
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta.add_theme_font_size_override("font_size", 19)
	meta.modulate = Color("a8b8cf")
	root.add_child(meta)
	move_label = Label.new()
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.add_theme_font_size_override("font_size", 24)
	root.add_child(move_label)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	board = GridContainer.new()
	board.columns = 5
	board.add_theme_constant_override("h_separation", 18)
	board.add_theme_constant_override("v_separation", 22)
	center.add_child(board)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	root.add_child(actions)
	var undo := Button.new()
	undo.text = "UNDO"
	undo.custom_minimum_size = Vector2(280, 82)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.text = "HINT"
	hint.custom_minimum_size = Vector2(280, 82)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.custom_minimum_size = Vector2(0, 44)
	root.add_child(hint_label)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 28)
	status_label.add_theme_color_override("font_color", Color("67e8cf"))
	root.add_child(status_label)

func load_level() -> void:
	completed = false
	selected = -1
	moves = 0
	history.clear()
	var config := level_config()
	color_count = int(config.colors)
	par_moves = int(config.par)
	title_label.text = "DAILY WATER SORT" if daily_mode else "WATER SORT  •  LEVEL %04d" % level_number
	var meta := get_node_or_null("Meta") as Label
	if meta:
		meta.text = "%s  •  %s  •  WORLD %d" % [difficulty().to_upper(), MultiGameManager.world_name(GAME_ID, MultiGameManager.world_for_level(level_number)).to_upper(), MultiGameManager.world_for_level(level_number)]
	tubes = generate_tubes(level_number, color_count)
	_restore_checkpoint()
	render_board()
	AnalyticsManager.track("water_sort_level_started", {"level": level_number, "difficulty": difficulty(), "daily": daily_mode})

func generate_tubes(seed_value: int, colors: int) -> Array:
	var result: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + colors * 97
	var permutation: Array[int] = []
	for i in range(colors):
		permutation.append(i)
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
	for child in board.get_children():
		child.queue_free()
	for i in range(tubes.size()):
		var button := Button.new()
		button.custom_minimum_size = Vector2(172, 315)
		button.text = tube_text(tubes[i])
		button.add_theme_font_size_override("font_size", 33)
		button.tooltip_text = "Tube %d" % (i + 1)
		button.modulate = Color(1.16, 1.16, 1.16) if i == selected else Color.WHITE
		button.pressed.connect(select_tube.bind(i))
		board.add_child(button)
	move_label.text = "MOVES  %d  •  PERFECT ≤ %d" % [moves, par_moves]

func tube_text(tube: Array) -> String:
	var lines: Array[String] = []
	for slot in range(CAPACITY - 1, -1, -1):
		if slot < tube.size():
			var index := int(tube[slot])
			lines.append(SYMBOLS[index])
		else:
			lines.append("·")
	return "\n".join(lines)

func select_tube(index: int) -> void:
	if completed:
		return
	hint_label.text = ""
	if selected < 0:
		if tubes[index].is_empty():
			return
		selected = index
		render_board()
		return
	if selected == index:
		selected = -1
		render_board()
		return
	if can_pour(selected, index):
		history.append({"tubes": tubes.duplicate(true), "moves": moves})
		pour(selected, index)
		moves += 1
		SaveManager.record_undo() if false else null
	selected = -1
	render_board()
	_save_checkpoint()
	if is_complete():
		complete_level()

func can_pour(from_idx: int, to_idx: int) -> bool:
	if from_idx < 0 or to_idx < 0 or from_idx >= tubes.size() or to_idx >= tubes.size():
		return false
	var source: Array = tubes[from_idx]
	var target: Array = tubes[to_idx]
	if source.is_empty() or target.size() >= CAPACITY:
		return false
	return target.is_empty() or int(target.back()) == int(source.back())

func pour(from_idx: int, to_idx: int) -> void:
	var source: Array = tubes[from_idx]
	var target: Array = tubes[to_idx]
	var color := int(source.back())
	var same_count := 0
	for i in range(source.size() - 1, -1, -1):
		if int(source[i]) != color:
			break
		same_count += 1
	var amount := mini(same_count, CAPACITY - target.size())
	for _i in range(amount):
		target.append(source.pop_back())

func undo_move() -> void:
	if history.is_empty() or completed:
		return
	var state: Dictionary = history.pop_back()
	tubes = state.tubes.duplicate(true)
	moves = int(state.moves)
	selected = -1
	SaveManager.record_undo()
	hint_label.text = "Move undone"
	render_board()
	_save_checkpoint()

func show_hint() -> void:
	if completed:
		return
	for from_idx in range(tubes.size()):
		if tubes[from_idx].is_empty():
			continue
		for to_idx in range(tubes.size()):
			if from_idx == to_idx or not can_pour(from_idx, to_idx):
				continue
			if not tubes[to_idx].is_empty() and int(tubes[to_idx].back()) == int(tubes[from_idx].back()):
				hint_label.text = "Try tube %d → tube %d" % [from_idx + 1, to_idx + 1]
				SaveManager.record_hint()
				return
	for from_idx in range(tubes.size()):
		for to_idx in range(tubes.size()):
			if from_idx != to_idx and can_pour(from_idx, to_idx):
				hint_label.text = "Try tube %d → tube %d" % [from_idx + 1, to_idx + 1]
				SaveManager.record_hint()
				return
	hint_label.text = "No legal move found — undo or retry"

func is_complete() -> bool:
	for tube in tubes:
		if tube.is_empty():
			continue
		if tube.size() != CAPACITY:
			return false
		for value in tube:
			if int(value) != int(tube[0]):
				return false
	return true

func complete_level() -> void:
	if completed:
		return
	completed = true
	MultiGameManager.clear_checkpoint(GAME_ID)
	var stars := 3 if moves <= par_moves else (2 if moves <= par_moves + maxi(6, color_count) else 1)
	if daily_mode:
		MultiGameManager.complete_daily(GAME_ID, 100 + stars * 25)
	else:
		MultiGameManager.complete_level(GAME_ID, level_number, stars, 25 + color_count * 2)
	status_label.text = "COMPLETE  •  %s  •  %d ★" % ["PERFECT" if stars == 3 else "CLEARED", stars]
	AnalyticsManager.track("water_sort_completed", {"level": level_number, "moves": moves, "stars": stars, "daily": daily_mode})
	await get_tree().create_timer(0.9).timeout
	finished.emit(-1 if daily_mode else level_number)

func restart_level() -> void:
	MultiGameManager.clear_checkpoint(GAME_ID)
	load_level()

func _save_checkpoint() -> void:
	if completed:
		return
	MultiGameManager.save_checkpoint(GAME_ID, {"level": level_number, "daily": daily_mode, "moves": moves, "tubes": tubes.duplicate(true), "history": history.duplicate(true)})

func _restore_checkpoint() -> void:
	var checkpoint := MultiGameManager.checkpoint(GAME_ID)
	if checkpoint.is_empty() or int(checkpoint.get("level", -1)) != level_number or bool(checkpoint.get("daily", false)) != daily_mode:
		return
	var saved_tubes = checkpoint.get("tubes", [])
	if saved_tubes is Array and not saved_tubes.is_empty():
		tubes = saved_tubes.duplicate(true)
		moves = maxi(0, int(checkpoint.get("moves", 0)))
		var saved_history = checkpoint.get("history", [])
		if saved_history is Array:
			history = saved_history.duplicate(true)

func _quit() -> void:
	_save_checkpoint()
	quit_requested.emit()
