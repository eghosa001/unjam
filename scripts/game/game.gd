extends Control

signal finished(level_number: int)
signal quit_requested

var level_number := 1
var custom_level_data: Dictionary = {}
var daily_mode := false
var level_data: Dictionary = {}
var width := 5
var height := 5
var moves := 0
var par_moves := 8
var rescue_id := "chick"
var rescue_pos := Vector2i.ZERO
var rescued := false
var pieces: Array[Dictionary] = []
var history: Array[Dictionary] = []
var chain_count := 0
var board_locked := false
var completion_rewards: Dictionary = {}

var board_grid: GridContainer
var moves_label: Label
var chain_label: Label
var rescue_label: Label
var hint_label: Label
var board_panel: PanelContainer

const DIRECTIONS := {
	"up": Vector2i.UP,
	"down": Vector2i.DOWN,
	"left": Vector2i.LEFT,
	"right": Vector2i.RIGHT
}
const WORLD_COLORS := ["182848", "163a5f", "273469", "522546", "214d3f", "4b2e63"]
const WORLD_ACCENTS := ["2dd4b6", "5da9ff", "8b7cf6", "ff6b7a", "55d68b", "c074ff"]

func _ready() -> void:
	level_data = custom_level_data.duplicate(true) if not custom_level_data.is_empty() else LevelManager.load_level(level_number)
	if level_data.is_empty():
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
		var p: Dictionary = raw_piece.duplicate(true)
		p["active"] = bool(p.get("active", true))
		pieces.append(p)
	AnalyticsManager.level_started(level_number)
	build_ui()
	render_board()

func world_index() -> int:
	var world := int(level_data.get("world", LevelManager.world_for_level(max(level_number, 1))))
	return posmod(world - 1, WORLD_COLORS.size())

func world_color() -> Color:
	return Color(WORLD_COLORS[world_index()])

func world_accent() -> Color:
	return Color(WORLD_ACCENTS[world_index()])

func style_box(color: Color, radius := 24, border_color := Color.TRANSPARENT, border_width := 0) -> StyleBoxFlat:
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

func style_button(button: Button, accent := false) -> void:
	var base := Color("263b62") if not accent else world_accent()
	button.add_theme_stylebox_override("normal", style_box(Color(base, 0.92), 22, Color(1,1,1,0.08), 1))
	button.add_theme_stylebox_override("hover", style_box(base.lightened(0.08), 22, Color(1,1,1,0.18), 2))
	button.add_theme_stylebox_override("pressed", style_box(base.darkened(0.10), 22, Color.WHITE, 2))
	button.add_theme_stylebox_override("disabled", style_box(Color("273044"), 22))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("7f899b"))

func build_ui() -> void:
	var world := int(level_data.get("world", 1))
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

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	outer.add_child(root)

	var top := HBoxContainer.new()
	var quit := Button.new()
	quit.text = "BACK"
	quit.custom_minimum_size = Vector2(112, 66)
	quit.add_theme_font_size_override("font_size", 19)
	style_button(quit)
	quit.pressed.connect(_quit)
	top.add_child(quit)

	var title := Label.new()
	title.text = "DAILY RESCUE" if daily_mode else "LEVEL %04d" % level_number
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	top.add_child(title)

	var restart := Button.new()
	restart.text = "RETRY"
	restart.custom_minimum_size = Vector2(112, 66)
	restart.add_theme_font_size_override("font_size", 19)
	style_button(restart)
	restart.pressed.connect(restart_level)
	top.add_child(restart)
	root.add_child(top)

	var meta_row := HBoxContainer.new()
	meta_row.alignment = BoxContainer.ALIGNMENT_CENTER
	meta_row.add_theme_constant_override("separation", 12)
	root.add_child(meta_row)
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
	status_panel.add_theme_stylebox_override("panel", style_box(Color(0.025, 0.05, 0.10, 0.88), 24, Color(1,1,1,0.09), 2))
	root.add_child(status_panel)
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
	root.add_child(board_holder)
	board_panel = PanelContainer.new()
	board_panel.add_theme_stylebox_override("panel", style_box(Color(0.018, 0.035, 0.075, 0.94), 38, Color(world_accent(),0.34), 2))
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
	root.add_child(actions)

	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 19)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.custom_minimum_size = Vector2(0, 52)
	root.add_child(hint_label)
	PremiumVisuals.entrance(root, 0.03)

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
	for child in board_grid.get_children():
		child.queue_free()
	moves_label.text = "MOVES  %d / %d" % [moves, par_moves]
	rescue_label.text = ("SAFE" if rescued else "RESCUE  " + rescue_id.to_upper())
	chain_label.text = "CHAIN ×%d" % chain_count if chain_count > 1 else ""
	var cell_size := 142 if width <= 5 else 116

	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var piece_index := get_piece_index_at(pos)
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
				var piece := pieces[piece_index]
				var button := PremiumPieceButton.new()
				button.custom_minimum_size = Vector2(cell_size, cell_size)
				button.tooltip_text = String(piece.get("type", "normal")).capitalize()
				button.configure(String(piece.get("type", "normal")), String(piece.get("direction", "right")), piece_color(String(piece.get("type", "normal"))))
				if String(piece.get("type", "normal")) in ["gate", "blocker"]:
					button.disabled = true
				else:
					button.pressed.connect(try_move.bind(piece_index))
				board_grid.add_child(button)
				_animate_cell(button, x, y)
			else:
				var empty := PanelContainer.new()
				empty.custom_minimum_size = Vector2(cell_size, cell_size)
				empty.add_theme_stylebox_override("panel", style_box(Color(1,1,1,0.025), 24, Color(1,1,1,0.035), 1))
				board_grid.add_child(empty)
				_animate_cell(empty, x, y)

func _animate_cell(cell: Control, x: int, y: int) -> void:
	cell.modulate.a = 0.0
	cell.scale = Vector2(0.92, 0.92)
	cell.pivot_offset = cell.custom_minimum_size / 2.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(cell, "modulate:a", 1.0, 0.13).set_delay(float(x + y) * 0.008)
	tween.tween_property(cell, "scale", Vector2.ONE, 0.18).set_delay(float(x + y) * 0.008).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func get_piece_index_at(pos: Vector2i) -> int:
	for i in range(pieces.size()):
		var p := pieces[i]
		if not bool(p.get("active", true)):
			continue
		if Vector2i(int(p.get("x", -1)), int(p.get("y", -1))) == pos:
			return i
	return -1

func piece_position(piece: Dictionary) -> Vector2i:
	return Vector2i(int(piece.get("x", 0)), int(piece.get("y", 0)))

func is_path_clear(index: int) -> bool:
	if index < 0 or index >= pieces.size():
		return false
	var piece := pieces[index]
	if not bool(piece.get("active", true)):
		return false
	var type := String(piece.get("type", "normal"))
	if type in ["blocker", "gate"]:
		return false
	var direction: Vector2i = DIRECTIONS.get(String(piece.get("direction", "right")), Vector2i.RIGHT)
	var pos := piece_position(piece) + direction
	while is_inside(pos):
		if not rescued and pos == rescue_pos:
			return false
		if get_piece_index_at(pos) >= 0:
			return false
		pos += direction
	return true

func is_inside(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height

func snapshot() -> Dictionary:
	return {"pieces": pieces.duplicate(true), "moves": moves, "rescued": rescued, "chain": chain_count}

func try_move(index: int) -> void:
	if board_locked:
		return
	hint_label.text = ""
	if not is_path_clear(index):
		chain_count = 0
		hint_label.text = "Blocked — clear its path first."
		FeedbackManager.blocked()
		PremiumVisuals.screen_flash(Color("ff6b7a"), 0.08)
		shake_board()
		return
	board_locked = true
	history.append(snapshot())
	moves += 1
	chain_count = 1
	FeedbackManager.escape(chain_count)
	escape_piece(index, true)
	await get_tree().create_timer(0.08).timeout
	resolve_rescue()
	if not rescued:
		render_board()
	board_locked = false

func shake_board() -> void:
	if board_panel == null:
		return
	var start := board_panel.position
	var tween := create_tween()
	tween.tween_property(board_panel, "position", start + Vector2(12, 0), 0.035)
	tween.tween_property(board_panel, "position", start - Vector2(10, 0), 0.035)
	tween.tween_property(board_panel, "position", start, 0.04)

func escape_piece(index: int, trigger_effect: bool) -> void:
	if index < 0 or index >= pieces.size() or not bool(pieces[index].get("active", true)):
		return
	var piece := pieces[index]
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
		PremiumVisuals.screen_flash(world_accent(), min(0.16, 0.04 + chain_count * 0.015))

func rotate_neighbors(center: Vector2i) -> void:
	for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var idx := get_piece_index_at(center + dir)
		if idx >= 0:
			var type := String(pieces[idx].get("type", "normal"))
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
			var idx := get_piece_index_at(Vector2i(x, y))
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
				chain_count += 1
			else:
				pieces[i]["direction"] = rotate_direction(String(pieces[i].get("direction", "right")))
				chain_count += 1

func rescue_has_exit() -> bool:
	if rescued:
		return true
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var pos := rescue_pos + direction
		var blocked := false
		while is_inside(pos):
			if get_piece_index_at(pos) >= 0:
				blocked = true
				break
			pos += direction
		if not blocked:
			return true
	return false

func resolve_rescue() -> void:
	if rescue_has_exit():
		rescued = true
		chain_count += 1
		FeedbackManager.rescue()
		PremiumVisuals.burst(Vector2(540, 860), world_accent(), 28)
		PremiumVisuals.screen_flash(world_accent(), 0.16)
		await get_tree().create_timer(0.12).timeout
		complete_level()

func complete_level() -> void:
	var stars := 3
	if moves > par_moves:
		stars = 2
	if moves > par_moves + 3:
		stars = 1
	completion_rewards = {}
	if daily_mode:
		SaveManager.complete_daily(String(level_data.get("daily_key", DailyChallenge.date_key())), 100)
	else:
		completion_rewards = SaveManager.complete_level(level_number, stars, rescue_id, 25 * stars)
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
	var achievements: Array = completion_rewards.get("achievements", [])
	for achievement in achievements:
		if achievement is Dictionary:
			lines.append("ACHIEVEMENT: %s" % String(achievement.get("title", "UNLOCKED")))
	return "\n".join(lines)

func show_result(stars: int) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.012, 0.022, 0.05, 0.96)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.modulate.a = 0.0
	add_child(overlay)
	var fade := create_tween()
	fade.tween_property(overlay, "modulate:a", 1.0, 0.18)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-345, -445)
	panel.custom_minimum_size = Vector2(690, 890)
	panel.add_theme_stylebox_override("panel", style_box(Color("111f38"), 38, world_accent(), 3))
	overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	panel.add_child(box)

	var token := RescueToken.new()
	token.custom_minimum_size = Vector2(180, 180)
	token.configure(rescue_id, Color("ffd166"))
	box.add_child(token)
	var title := Label.new()
	title.text = "DAILY COMPLETE" if daily_mode else "RESCUE COMPLETE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	box.add_child(title)
	var star_label := Label.new()
	star_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.add_theme_font_size_override("font_size", 56)
	star_label.add_theme_color_override("font_color", Color("ffd166"))
	box.add_child(star_label)
	var reward := 100 if daily_mode else 25 * stars
	var stats := Label.new()
	stats.text = "%d MOVES   •   +%d COINS" % [moves, reward]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 22)
	box.add_child(stats)
	var premium_summary := reward_summary()
	if not premium_summary.is_empty():
		var reward_card := PanelContainer.new()
		reward_card.custom_minimum_size = Vector2(560, 120)
		reward_card.add_theme_stylebox_override("panel", style_box(Color(world_accent(),0.12), 24, Color(world_accent(),0.55), 2))
		var reward_label := Label.new()
		reward_label.text = premium_summary
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward_label.add_theme_font_size_override("font_size", 18)
		reward_card.add_child(reward_label)
		box.add_child(reward_card)
		PremiumVisuals.burst(Vector2(540, 540), world_accent(), 24)

	var double_reward := Button.new()
	double_reward.text = "DOUBLE REWARD"
	double_reward.custom_minimum_size = Vector2(470, 82)
	double_reward.add_theme_font_size_override("font_size", 23)
	style_button(double_reward, true)
	double_reward.pressed.connect(func():
		double_reward.disabled = true
		AdManager.show_rewarded("double_reward", func(): SaveManager.add_coins(reward))
		double_reward.text = "REWARD DOUBLED"
	)
	box.add_child(double_reward)

	var next := Button.new()
	next.text = "BACK HOME" if daily_mode else ("NEXT RESCUE" if LevelManager.has_level(level_number + 1) else "CAMPAIGN COMPLETE")
	next.custom_minimum_size = Vector2(470, 88)
	next.add_theme_font_size_override("font_size", 24)
	style_button(next)
	next.pressed.connect(func():
		if AdManager.should_show_interstitial(): AdManager.show_interstitial()
		finished.emit(-1 if daily_mode else level_number)
		queue_free()
	)
	box.add_child(next)
	PremiumVisuals.entrance(panel, 0.08)

func undo_move() -> void:
	if history.is_empty() or rescued or board_locked:
		return
	var state: Dictionary = history.pop_back()
	pieces = state["pieces"].duplicate(true)
	moves = int(state["moves"])
	rescued = bool(state["rescued"])
	chain_count = int(state["chain"])
	SaveManager.record_undo()
	FeedbackManager.tap()
	hint_label.text = "Move undone."
	render_board()

func show_hint() -> void:
	if board_locked:
		return
	SaveManager.record_hint()
	FeedbackManager.tap()
	for i in range(pieces.size()):
		if is_path_clear(i):
			var p := pieces[i]
			hint_label.text = "Try the %s at row %d, column %d." % [String(p.get("type", "normal")).capitalize(), int(p.get("y", 0)) + 1, int(p.get("x", 0)) + 1]
			return
	hint_label.text = "No direct escape is available. Undo or restart and change the order."

# Intentionally does not load Game.tscn here. The production subclass owns restart
# so the base script remains free of a circular scene -> script -> scene dependency.
func restart_level() -> void:
	push_warning("Base gameplay restart invoked; production gameplay overrides this method.")

func _quit() -> void:
	quit_requested.emit()
	queue_free()