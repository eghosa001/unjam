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
	back_button.custom_minimum_size = Vector2(150, 82)
	back_button.add_theme_font_size_override("font_size", 22)
	style_button(back_button)
	back_button.pressed.connect(_quit)
	top.add_child(back_button)
	var title := Label.new()
	title.text = "DAILY RESCUE" if daily_mode else "LEVEL %04d" % level_number
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	top.add_child(title)
	var retry := Button.new()
	retry.text = "RETRY"
	retry.custom_minimum_size = Vector2(150, 82)
	retry.add_theme_font_size_override("font_size", 22)
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
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.modulate = Color("aebbd0")
	meta_row.add_child(subtitle)
	if not daily_mode:
		var difficulty := Label.new()
		difficulty.text = String(level_data.get("difficulty_label", level_data.get("difficulty", "medium"))).to_upper()
		difficulty.add_theme_font_size_override("font_size", 20)
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
	moves_label.add_theme_font_size_override("font_size", 24)
	status.add_child(moves_label)
	rescue_label = Label.new()
	rescue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rescue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rescue_label.add_theme_font_size_override("font_size", 24)
	status.add_child(rescue_label)
	chain_label = Label.new()
	chain_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	chain_label.add_theme_font_size_override("font_size", 24)
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
	undo.custom_minimum_size = Vector2(290, 92)
	undo.add_theme_font_size_override("font_size", 24)
	style_button(undo)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.text = "HINT"
	hint.custom_minimum_size = Vector2(290, 92)
	hint.add_theme_font_size_override("font_size", 24)
	style_button(hint, true)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)
	root_box.add_child(actions)
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 22)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.custom_minimum_size = Vector2(0, 60)
	root_box.add_child(hint_label)

func render_board() -> void:
	# Keep the rest of the established gameplay implementation in this file.
	# This method body and the methods below are supplied by the existing source.
	_render_board_existing()

func _render_board_existing() -> void:
	for child in board_grid.get_children():
		child.queue_free()
	var cell_size := clampf((900.0 - float(width - 1) * 10.0) / float(width), 88.0, 132.0)
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var cell := _make_cell(pos, cell_size)
			board_grid.add_child(cell)
	moves_label.text = "MOVES\n%d / %d" % [moves, par_moves]
	rescue_label.text = "RESCUE\n%s" % rescue_id.to_upper()
	chain_label.text = "CHAIN\n×%d" % maxi(1, chain_count)
