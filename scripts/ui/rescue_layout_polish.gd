extends Node

# GAME_FIRST_RESCUE

var live_label: Label
var route_bar: ProgressBar
var timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_polish_layout")

func _process(delta: float) -> void:
	timer += delta
	if timer < 0.15:
		return
	timer = 0.0
	_update_live_context()

func _polish_layout() -> void:
	var game := get_parent() as Control
	if game == null:
		return
	var root_box: VBoxContainer = _find_primary_vbox(game)
	if root_box != null:
		root_box.alignment = BoxContainer.ALIGNMENT_BEGIN
		root_box.add_theme_constant_override("separation", 10)
		var outer := root_box.get_parent() as MarginContainer
		if outer != null:
			outer.add_theme_constant_override("margin_top", 18)
			outer.add_theme_constant_override("margin_bottom", 18)
		_add_live_context(root_box)
	var board_holder: CenterContainer = _find_board_holder(game)
	if board_holder != null:
		board_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		board_holder.custom_minimum_size = Vector2(0, 980)
	var board_panel: PanelContainer = _find_board_panel(game)
	if board_panel != null:
		board_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		board_panel.add_theme_stylebox_override("panel", PremiumDesignSystem.box(Color(0.008, 0.024, 0.052, 0.98), 36, Color(PremiumDesignSystem.accent_for_game("rescue_rush"), 0.52), 3, 10, true))
	_update_live_context()

func _add_live_context(root: VBoxContainer) -> void:
	if root.get_node_or_null("RescueRunDeck") != null:
		return
	var accent := PremiumDesignSystem.accent_for_game("rescue_rush")
	var deck := PanelContainer.new()
	deck.name = "RescueRunDeck"
	deck.custom_minimum_size = Vector2(0, 116)
	deck.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	deck.add_theme_stylebox_override("panel", PremiumDesignSystem.box(Color(0.018, 0.043, 0.085, 0.92), 24, Color(accent, 0.30), 2, 4, true))
	root.add_child(deck)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	deck.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)
	route_bar = ProgressBar.new()
	route_bar.show_percentage = false
	route_bar.custom_minimum_size = Vector2(720, 14)
	route_bar.add_theme_stylebox_override("background", PremiumDesignSystem.box(Color("102642"), 7, Color.TRANSPARENT, 0, 0, true))
	route_bar.add_theme_stylebox_override("fill", PremiumDesignSystem.box(accent, 7, accent.lightened(0.10), 1, 0, true))
	box.add_child(route_bar)
	live_label = Label.new()
	live_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	live_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	live_label.add_theme_font_size_override("font_size", 16)
	live_label.add_theme_color_override("font_color", Color("c7d5e5"))
	box.add_child(live_label)

func _update_live_context() -> void:
	var game := get_parent()
	if game == null or live_label == null or route_bar == null:
		return
	var par_moves := int(game.get("par_moves")) if game.get("par_moves") != null else 1
	var moves := int(game.get("moves")) if game.get("moves") != null else 0
	var chain_count := int(game.get("chain_count")) if game.get("chain_count") != null else 0
	var rescued := bool(game.get("rescued")) if game.get("rescued") != null else false
	route_bar.max_value = maxf(1.0, float(par_moves))
	route_bar.value = minf(float(moves), float(par_moves))
	var state := "SAFE" if rescued else "OPEN THE ESCAPE LANE"
	live_label.text = "%d / %d MOVES  •  CHAIN x%d  •  %s" % [moves, par_moves, maxi(1, chain_count), state]

func _find_primary_vbox(root: Node) -> VBoxContainer:
	for child in root.get_children():
		if child is MarginContainer:
			for grandchild in child.get_children():
				if grandchild is VBoxContainer:
					return grandchild as VBoxContainer
	return null

func _find_board_holder(root: Node) -> CenterContainer:
	for node in _descendants(root):
		if node is CenterContainer:
			for child in node.get_children():
				if child is PanelContainer and _contains_grid(child):
					return node as CenterContainer
	return null

func _find_board_panel(root: Node) -> PanelContainer:
	for node in _descendants(root):
		if node is PanelContainer and _contains_grid(node):
			return node as PanelContainer
	return null

func _contains_grid(root: Node) -> bool:
	if root is GridContainer:
		return true
	for child in root.get_children():
		if _contains_grid(child):
			return true
	return false

func _descendants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in root.get_children():
		result.append(child)
		result.append_array(_descendants(child))
	return result
