extends Control

signal finished(level_number: int)
signal quit_requested

var level_number: int = 1
var custom_level_data: Dictionary = {}
var daily_mode: bool = false
var level_data: Dictionary = {}
var width: int = 5
var height: int = 5
var moves: int = 0
var par_moves: int = 8
var rescue_id: String = "chick"
var rescue_pos: Vector2i = Vector2i.ZERO
var rescued: bool = false
var pieces: Array[Dictionary] = []
var history: Array[Dictionary] = []
var chain_count: int = 0
var board_locked: bool = false
var completion_rewards: Dictionary = {}
var hints_used_this_level: int = 0

var board_grid: GridContainer
var moves_label: Label
var chain_label: Label
var rescue_label: Label
var hint_label: Label
var board_panel: PanelContainer

const DIRECTIONS: Dictionary = {
	"up": Vector2i.UP,
	"down": Vector2i.DOWN,
	"left": Vector2i.LEFT,
	"right": Vector2i.RIGHT
}
const WORLD_COLORS: Array[String] = ["182848", "163a5f", "273469", "522546", "214d3f", "4b2e63"]
const WORLD_ACCENTS: Array[String] = ["2dd4b6", "5da9ff", "8b7cf6", "ff6b7a", "55d68b", "c074ff"]

func _ready() -> void:
	level_data = custom_level_data.duplicate(true) if not custom_level_data.is_empty() else LevelManager.load_level(level_number)
	if level_data.is_empty():
		push_error("Level %d could not be loaded." % level_number)
		quit_requested.emit()
		queue_free()
		return
	width = int(level_data.get("width", 5))
	height = int(level_data.get("height", 5))
	par_moves = int(level_data.get("par_moves", 8))
	rescue_id = String(level_data.get("rescue_id", "chick"))
	var rp: Array = level_data.get("rescue", [2, 2])
	rescue_pos = Vector2i(int(rp[0]), int(rp[1]))
	pieces.clear()
	for raw_piece in level_data.get("pieces", []):
		if not raw_piece is Dictionary:
			continue
		var piece: Dictionary = raw_piece.duplicate(true)
		piece["active"] = bool(piece.get("active", true))
		pieces.append(piece)
	AnalyticsManager.level_started(level_number)
	build_ui()
	_restore_checkpoint()
	render_board()

func world_index() -> int:
	var world: int = int(level_data.get("world", LevelManager.world_for_level(maxi(level_number, 1))))
	return posmod(world - 1, WORLD_COLORS.size())

func world_color() -> Color:
	return Color(WORLD_COLORS[world_index()])

func world_accent() -> Color:
	return Color(WORLD_ACCENTS[world_index()])

func style_box(color: Color, radius: int = 24, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if border_width > 0:
		style.border_width_left = border_width
		style.border_width_right = border_width
		style.border_width_top = border_width
		style.border_width_bottom = border_width
		style.border_color = border_color
	return style

func style_button(button: Button, accent: bool = false) -> void:
	var base: Color = world_accent() if accent else Color("263b62")
	button.add_theme_stylebox_override("normal", style_box(Color(base, 0.92), 22, Color(1, 1, 1, 0.08), 1))
	button.add_theme_stylebox_override("hover", style_box(base.lightened(0.08), 22, Color(1, 1, 1, 0.18), 2))
	button.add_theme_stylebox_override("pressed", style_box(base.darkened(0.10), 22, Color.WHITE, 2))
	button.add_theme_stylebox_override("disabled", style_box(Color("273044"), 22))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("7f899b"))

func build_ui() -> void:
	var world: int = int(level_data.get("world", 1))
	var backdrop := PremiumBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(world_color().darkened(0.42), world_accent(), world - 1)
	add_child(backdrop)
	PremiumVisuals.set_accent(world_accent())
	PremiumVisuals.ambient_sparkles(12)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 42)
	outer.add_theme_constant_override("margin_right", 42)
	outer.add_theme_constant_override("margin_top", 54)
	outer.add_theme_constant_override("margin_bottom", 54)
	add_child(outer)
	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 18)
	outer.add_child(root_box)

	var top := HBoxContainer.new()
	var back_button := Button.new()
	back_button.text = "BACK"
	back_button.custom_minimum_size = Vector2(112, 66)
	back_button.add_theme_font_size_override("font_size", 19)
	style_button(back_button)
	back_button.pressed.connect(_quit)
	top.add_child(back_button)
	var title := Label.new()
	title.text = "DAILY RESCUE" if daily_mode else "LEVEL %04d" % level_number
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	top.add_child(title)
	var retry := Button.new()
	retry.text = "RETRY"
	retry.custom_minimum_size = Vector2(112, 66)
	retry.add_theme_font_size_override("font_size", 19)
	style_button(retry)
	retry.pressed.connect(restart_level)
	top.add_child(retry)
	root_box.add_child(top)

	var meta_row := HBoxContainer.new()
	meta_row.alignment = BoxContainer.ALIGNMENT_CENTER
	meta_row.add_theme_constant_override("separation", 12)
	root_box.add_child(meta_row)
	var subtitle := Label.new()
	subtitle.text = "TODAY'S CHALLENGE" if daily_mode else LevelManager.world_name(world).to_upper()
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.modulate = Color("aebbd0")
	meta_row.add_child(subtitle)
	if not daily_mode:
		var difficulty := Label.new()
		difficulty.text = String(level_data.get("difficulty_label", "medium")).to_upper()
		difficulty.add_theme_font_size_override("font_size", 16)
		difficulty.add_theme_color_override("font_color", world_accent())
		meta_row.add_child(difficulty)

	var status_panel := PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", style_box(Color(0.025, 0.05, 0.10, 0.88), 24, Color(1, 1, 1, 0.09), 2))
	root_box.add_child(status_panel)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 16)
	status_panel.add_child(status)
	moves_label = Label.new()
	moves_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moves_label.add_theme_font_size_override("font_size", 22)
	status.add_child(moves_label)
	rescue_label = Label.new()
	rescue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rescue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rescue_label.add_theme_font_size_override("font_size", 22)
	status.add_child(rescue_label)
	chain_label = Label.new()
	chain_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	chain_label.add_theme_font_size_override("font_size", 22)
	chain_label.add_theme_color_override("font_color", Color("ffd166"))
	status.add_child(chain_label)

	var board_holder := CenterContainer.new()
	board_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(board_holder)
	board_panel = PanelContainer.new()
	board_panel.add_theme_stylebox_override("panel", style_box(Color(0.018, 0.035, 0.075, 0.94), 38, Color(world_accent(), 0.34), 2))
	board_holder.add_child(board_panel)
	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 26)
	board_margin.add_theme_constant_override("margin_right", 26)
	board_margin.add_theme_constant_override("margin_top", 26)
	board_margin.add_theme_constant_override("margin_bottom", 26)
	board_panel.add_child(board_margin)
	board_grid = GridContainer.new()
	board_grid.columns = width
	board_grid.add_theme_constant_override("h_separation", 10)
	board_grid.add_theme_constant_override("v_separation", 10)
	board_margin.add_child(board_grid)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	var undo := Button.new()
	undo.text = "UNDO"
	undo.custom_minimum_size = Vector2(250, 80)
	undo.add_theme_font_size_override("font_size", 22)
	style_button(undo)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.text = "HINT"
	hint.custom_minimum_size = Vector2(250, 80)
	hint.add_theme_font_size_override("font_size", 22)
	style_button(hint, true)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)
	root_box.add_child(actions)
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 19)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.custom_minimum_size = Vector2(0, 52)
	root_box.add_child(hint_label)
	PremiumVisuals.entrance(root_box, 0.03)

func piece_color(type: String) -> Color:
	match type:
		"rotate": return Color("7656c9")
		"key": return Color("d89b36")
		"gate": return Color("754668")
		"bomb": return Color("c4534c")
		"linked": return Color("2b9e91")
		"blocker": return Color("343b4a")
		_: return Color("2f5f91").lerp(world_accent(), 0.25)

func render_board() -> void:
	if board_grid == null:
		return
	for child in board_grid.get_children():
		child.queue_free()
	moves_label.text = "MOVES  %d / %d" % [moves, par_moves]
	rescue_label.text = "SAFE" if rescued else "RESCUE  " + rescue_id.to_upper()
	chain_label.text = "CHAIN ×%d" % chain_count if chain_count > 1 else ""
	var cell_size: int = 142 if width <= 5 else 116
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var piece_index: int = get_piece_index_at(pos)
			if not rescued and pos == rescue_pos:
				var slot := PanelContainer.new()
				slot.custom_minimum_size = Vector2(cell_size, cell_size)
				slot.add_theme_stylebox_override("panel", style_box(Color("18243d"), 28, Color("ffd166"), 2))
				var token := RescueToken.new()
				token.custom_minimum_size = Vector2(cell_size, cell_size)
				token.configure(rescue_id, Color("ffd166"))
				slot.add_child(token)
				board_grid.add_child(slot)
				_animate_cell(slot, x, y)
			elif piece_index >= 0:
				var piece: Dictionary = pieces[piece_index]
				var button := PremiumPieceButton.new()
				button.custom_minimum_size = Vector2(cell_size, cell_size)
				button.tooltip_text = String(piece.get("type", "normal")).capitalize()
				button.configure(String(piece.get("type", "normal")), String(piece.get("direction", "right")), piece_color(String(piece.get("type", "normal"))))
				button.disabled = String(piece.get("type", "normal")) in ["gate", "blocker"]
				if not button.disabled:
					button.pressed.connect(try_move.bind(piece_index))
				board_grid.add_child(button)
				_animate_cell(button, x, y)
			else:
				var empty := PanelContainer.new()
				empty.custom_minimum_size = Vector2(cell_size, cell_size)
				empty.add_theme_stylebox_override("panel", style_box(Color(1, 1, 1, 0.025), 24, Color(1, 1, 1, 0.035), 1))
				board_grid.add_child(empty)
				_animate_cell(empty, x, y)

func _animate_cell(cell: Control, x: int, y: int) -> void:
	cell.modulate.a = 0.0
	cell.scale = Vector2(0.92, 0.92)
	cell.pivot_offset = cell.custom_minimum_size / 2.0
	var tween := create_tween()
	tween.set_parallel(true)
	var delay: float = float(x + y) * 0.008
	tween.tween_property(cell, "modulate:a", 1.0, 0.13).set_delay(delay)
	tween.tween_property(cell, "scale", Vector2.ONE, 0.18).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func get_piece_index_at(pos: Vector2i) -> int:
	for i in range(pieces.size()):
		var piece: Dictionary = pieces[i]
		if bool(piece.get("active", true)) and Vector2i(int(piece.get("x", -1)), int(piece.get("y", -1))) == pos:
			return i
	return -1

func piece_position(piece: Dictionary) -> Vector2i:
	return Vector2i(int(piece.get("x", 0)), int(piece.get("y", 0)))

func is_inside(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height

func is_path_clear(index: int) -> bool:
	if index < 0 or index >= pieces.size():
		return false
	var piece: Dictionary = pieces[index]
	if not bool(piece.get("active", true)):
		return false
	var type: String = String(piece.get("type", "normal"))
	if type in ["blocker", "gate"]:
		return false
	var direction: Vector2i = DIRECTIONS.get(String(piece.get("direction", "right")), Vector2i.RIGHT)
	var pos: Vector2i = piece_position(piece) + direction
	while is_inside(pos):
		if not rescued and pos == rescue_pos:
			return false
		if get_piece_index_at(pos) >= 0:
			return false
		pos += direction
	return true

func snapshot() -> Dictionary:
	return {"pieces": pieces.duplicate(true), "moves": moves, "rescued": rescued, "chain": chain_count, "hints": hints_used_this_level}

func _legal_map() -> Dictionary:
	var result: Dictionary = {}
	for i in range(pieces.size()):
		result[i] = is_path_clear(i)
	return result

func try_move(index: int) -> void:
	if board_locked or rescued:
		return
	hint_label.text = ""
	if not is_path_clear(index):
		chain_count = 0
		hint_label.text = "Blocked — clear its path first."
		FeedbackManager.blocked()
		shake_board()
		return
	board_locked = true
	var legal_before: Dictionary = _legal_map()
	history.append(snapshot())
	moves += 1
	chain_count = 1
	FeedbackManager.escape(chain_count)
	escape_piece(index, true)
	await get_tree().create_timer(0.07).timeout
	await _resolve_cascades(legal_before)
	await resolve_rescue()
	if not rescued:
		render_board()
		_save_checkpoint()
	board_locked = false

func _resolve_cascades(previous_legal: Dictionary) -> void:
	var baseline: Dictionary = previous_legal.duplicate()
	var guard: int = 0
	var max_steps: int = maxi(8, pieces.size() * 2)
	while guard < max_steps:
		guard += 1
		var newly_opened: Array[int] = []
		for i in range(pieces.size()):
			if bool(pieces[i].get("active", true)) and is_path_clear(i) and not bool(baseline.get(i, false)):
				newly_opened.append(i)
		if newly_opened.is_empty():
			break
		var before_batch: Dictionary = _legal_map()
		for index in newly_opened:
			if index >= 0 and index < pieces.size() and bool(pieces[index].get("active", true)) and is_path_clear(index):
				chain_count += 1
				FeedbackManager.escape(chain_count)
				escape_piece(index, true)
				PremiumVisuals.burst(Vector2(540, 860), world_accent(), mini(18, 5 + chain_count))
				await get_tree().create_timer(0.045).timeout
		baseline = before_batch
	if chain_count >= 3:
		AnalyticsManager.track("cascade", {"level": level_number, "chain": chain_count})

func shake_board() -> void:
	if board_panel == null:
		return
	var start: Vector2 = board_panel.position
	var tween := create_tween()
	tween.tween_property(board_panel, "position", start + Vector2(12, 0), 0.035)
	tween.tween_property(board_panel, "position", start - Vector2(10, 0), 0.035)
	tween.tween_property(board_panel, "position", start, 0.04)

func escape_piece(index: int, trigger_effect: bool) -> void:
	if index < 0 or index >= pieces.size() or not bool(pieces[index].get("active", true)):
		return
	var piece: Dictionary = pieces[index]
	pieces[index]["active"] = false
	if not trigger_effect:
		return
	match String(piece.get("type", "normal")):
		"rotate": rotate_neighbors(piece_position(piece))
		"key": open_gates(String(piece.get("key_id", "default")))
		"bomb": explode_at(piece_position(piece))
		"linked": activate_link(String(piece.get("link_id", "")), index)
	if chain_count > 1:
		FeedbackManager.effect()

func rotate_neighbors(center: Vector2i) -> void:
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for direction in directions:
		var idx: int = get_piece_index_at(center + direction)
		if idx >= 0:
			var type: String = String(pieces[idx].get("type", "normal"))
			if type not in ["blocker", "gate"]:
				pieces[idx]["direction"] = rotate_direction(String(pieces[idx].get("direction", "right")))
				chain_count += 1

func rotate_direction(direction: String) -> String:
	match direction:
		"up": return "right"
		"right": return "down"
		"down": return "left"
		_: return "up"

func open_gates(key_id: String) -> void:
	for i in range(pieces.size()):
		if bool(pieces[i].get("active", true)) and String(pieces[i].get("type", "")) == "gate" and String(pieces[i].get("key_id", "default")) == key_id:
			pieces[i]["active"] = false
			chain_count += 1

func explode_at(center: Vector2i) -> void:
	for y in range(center.y - 1, center.y + 2):
		for x in range(center.x - 1, center.x + 2):
			var idx: int = get_piece_index_at(Vector2i(x, y))
			if idx >= 0 and String(pieces[idx].get("type", "")) != "gate":
				pieces[idx]["active"] = false
				chain_count += 1

func activate_link(link_id: String, source_index: int) -> void:
	if link_id.is_empty():
		return
	for i in range(pieces.size()):
		if i == source_index or not bool(pieces[i].get("active", true)):
			continue
		if String(pieces[i].get("type", "")) == "linked" and String(pieces[i].get("link_id", "")) == link_id:
			if is_path_clear(i):
				pieces[i]["active"] = false
			else:
				pieces[i]["direction"] = rotate_direction(String(pieces[i].get("direction", "right")))
			chain_count += 1

func rescue_has_exit() -> bool:
	if rescued:
		return true
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for direction in directions:
		var pos: Vector2i = rescue_pos + direction
		var blocked: bool = false
		while is_inside(pos):
			if get_piece_index_at(pos) >= 0:
				blocked = true
				break
			pos += direction
		if not blocked:
			return true
	return false

func resolve_rescue() -> void:
	if not rescue_has_exit():
		return
	rescued = true
	chain_count += 1
	FeedbackManager.rescue()
	PremiumVisuals.burst(Vector2(540, 860), world_accent(), 28)
	PremiumVisuals.screen_flash(world_accent(), 0.16)
	await get_tree().create_timer(0.12).timeout
	complete_level()

func complete_level() -> void:
	var stars: int = 3
	if moves > par_moves:
		stars = 2
	if moves > par_moves + 3:
		stars = 1
	completion_rewards = {}
	_clear_checkpoint(false)
	if daily_mode:
		SaveManager.complete_daily(String(level_data.get("daily_key", DailyChallenge.date_key())), 100)
	else:
		completion_rewards = SaveManager.complete_level(level_number, stars, rescue_id, 25 * stars)
		RetentionManager.record_level_complete(level_number, stars, moves, par_moves, chain_count, rescue_id, hints_used_this_level)
	AdManager.note_level_completed()
	AnalyticsManager.level_completed(level_number, moves, stars)
	show_result(stars)

func reward_summary() -> String:
	if completion_rewards.is_empty():
		return ""
	var lines: Array[String] = []
	if bool(completion_rewards.get("perfect", false)):
		lines.append("PERFECT CLEAR  •  STREAK %d" % int(completion_rewards.get("perfect_streak", 0)))
	if bool(completion_rewards.get("milestone", false)):
		lines.append("MILESTONE CHEST UNLOCKED")
	if bool(completion_rewards.get("world_badge", false)):
		lines.append("WORLD %d BADGE EARNED" % int(completion_rewards.get("world", 0)))
	if int(completion_rewards.get("prestige", 0)) > 0:
		lines.append("+%d PRESTIGE" % int(completion_rewards.get("prestige", 0)))
	return "\n".join(lines)

func show_result(stars: int) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.012, 0.022, 0.05, 0.96)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-345, -405)
	panel.custom_minimum_size = Vector2(690, 810)
	panel.add_theme_stylebox_override("panel", style_box(Color("111f38"), 38, world_accent(), 3))
	overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	panel.add_child(box)
	var token := RescueToken.new()
	token.custom_minimum_size = Vector2(170, 170)
	token.configure(rescue_id, Color("ffd166"))
	box.add_child(token)
	var title := Label.new()
	title.text = "DAILY COMPLETE" if daily_mode else "RESCUE COMPLETE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	box.add_child(title)
	var star_label := Label.new()
	star_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.add_theme_font_size_override("font_size", 54)
	star_label.add_theme_color_override("font_color", Color("ffd166"))
	box.add_child(star_label)
	var base_reward: int = 100 if daily_mode else int(completion_rewards.get("base_coins", 0))
	var bonus_reward: int = 0 if daily_mode else int(completion_rewards.get("bonus_coins", 0))
	var stats := Label.new()
	stats.text = "%d MOVES   •   +%d COINS" % [moves, base_reward + bonus_reward]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 22)
	box.add_child(stats)
	var summary: String = reward_summary()
	if not summary.is_empty():
		var reward_label := Label.new()
		reward_label.text = summary
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_label.add_theme_font_size_override("font_size", 18)
		box.add_child(reward_label)
	var double_reward := Button.new()
	double_reward.text = "DOUBLE BASE REWARD" if base_reward > 0 else "REWARD CLAIMED"
	double_reward.disabled = base_reward <= 0
	double_reward.custom_minimum_size = Vector2(470, 78)
	style_button(double_reward, true)
	double_reward.pressed.connect(func() -> void:
		double_reward.disabled = true
		AdManager.show_rewarded("double_reward", func() -> void: SaveManager.add_coins(base_reward))
		double_reward.text = "BASE REWARD DOUBLED"
	)
	box.add_child(double_reward)
	var next := Button.new()
	next.text = "BACK HOME" if daily_mode else ("NEXT RESCUE" if LevelManager.has_level(level_number + 1) else "CAMPAIGN COMPLETE")
	next.custom_minimum_size = Vector2(470, 84)
	style_button(next)
	next.pressed.connect(func() -> void:
		if AdManager.should_show_interstitial():
			AdManager.show_interstitial()
		finished.emit(-1 if daily_mode else level_number)
		queue_free()
	)
	box.add_child(next)
	PremiumVisuals.entrance(panel, 0.08)

func undo_move() -> void:
	if history.is_empty() or rescued or board_locked:
		return
	var state: Dictionary = history.pop_back()
	pieces = state.get("pieces", []).duplicate(true)
	moves = int(state.get("moves", 0))
	rescued = bool(state.get("rescued", false))
	chain_count = int(state.get("chain", 0))
	hints_used_this_level = int(state.get("hints", hints_used_this_level))
	SaveManager.record_undo()
	FeedbackManager.tap()
	hint_label.text = "Move undone."
	render_board()
	_save_checkpoint()

func show_hint() -> void:
	if board_locked or rescued:
		return
	hints_used_this_level += 1
	SaveManager.record_hint()
	FeedbackManager.tap()
	AnalyticsManager.hint_used(level_number)
	var index: int = PuzzleSolver.first_solution_move(level_data, pieces, 6000)
	if index >= 0 and index < pieces.size():
		var piece: Dictionary = pieces[index]
		hint_label.text = "Solution hint: move the %s at row %d, column %d." % [String(piece.get("type", "normal")).capitalize(), int(piece.get("y", 0)) + 1, int(piece.get("x", 0)) + 1]
		_save_checkpoint()
		return
	hint_label.text = "Dead end. Use Undo or Retry to recover."

func restart_level() -> void:
	AnalyticsManager.level_restarted(level_number)
	_clear_checkpoint(true)
	var original_level: int = level_number
	var original_daily: bool = daily_mode
	var original_custom: Dictionary = custom_level_data.duplicate(true)
	for child in get_children():
		child.queue_free()
	level_number = original_level
	daily_mode = original_daily
	custom_level_data = original_custom
	level_data = {}
	pieces.clear()
	history.clear()
	moves = 0
	chain_count = 0
	rescued = false
	board_locked = false
	hints_used_this_level = 0
	call_deferred("_restart_in_place")

func _restart_in_place() -> void:
	level_data = custom_level_data.duplicate(true) if not custom_level_data.is_empty() else LevelManager.load_level(level_number)
	width = int(level_data.get("width", 5))
	height = int(level_data.get("height", 5))
	par_moves = int(level_data.get("par_moves", 8))
	rescue_id = String(level_data.get("rescue_id", "chick"))
	var rp: Array = level_data.get("rescue", [2, 2])
	rescue_pos = Vector2i(int(rp[0]), int(rp[1]))
	for raw_piece in level_data.get("pieces", []):
		if raw_piece is Dictionary:
			var piece: Dictionary = raw_piece.duplicate(true)
			piece["active"] = true
			pieces.append(piece)
	build_ui()
	render_board()

func _save_checkpoint() -> void:
	if rescued or level_data.is_empty():
		return
	SaveManager.data["active_run"] = {
		"level": level_number,
		"daily": daily_mode,
		"daily_key": String(level_data.get("daily_key", "")),
		"level_data": level_data.duplicate(true) if daily_mode else {},
		"pieces": pieces.duplicate(true),
		"moves": moves,
		"chain": chain_count,
		"hints": hints_used_this_level,
		"saved_at": int(Time.get_unix_time_from_system())
	}
	SaveManager.save()

func _restore_checkpoint() -> void:
	var raw: Variant = SaveManager.data.get("active_run", {})
	if not raw is Dictionary:
		return
	var checkpoint: Dictionary = raw
	if checkpoint.is_empty() or int(checkpoint.get("level", -1)) != level_number or bool(checkpoint.get("daily", false)) != daily_mode:
		return
	if daily_mode and String(checkpoint.get("daily_key", "")) != String(level_data.get("daily_key", "")):
		return
	var restored: Variant = checkpoint.get("pieces", [])
	if not restored is Array or restored.size() != pieces.size():
		return
	var clean: Array[Dictionary] = []
	for raw_piece in restored:
		if not raw_piece is Dictionary:
			return
		clean.append(raw_piece.duplicate(true))
	pieces = clean
	moves = maxi(0, int(checkpoint.get("moves", 0)))
	chain_count = maxi(0, int(checkpoint.get("chain", 0)))
	hints_used_this_level = maxi(0, int(checkpoint.get("hints", 0)))
	history.clear()
	if hint_label != null:
		hint_label.text = "Rescue restored from your last checkpoint."

func _clear_checkpoint(save_now: bool = true) -> void:
	SaveManager.data["active_run"] = {}
	if save_now:
		SaveManager.save()

func _quit() -> void:
	_save_checkpoint()
	quit_requested.emit()
	queue_free()
