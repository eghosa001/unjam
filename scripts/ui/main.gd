extends Control

var content: Control

func _ready() -> void:
	build_home()

func clear_content() -> void:
	if content and is_instance_valid(content):
		content.queue_free()
	content = Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content)

func make_button(text_value: String, size := Vector2(420, 92)) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = size
	b.add_theme_font_size_override("font_size", 30)
	return b

func build_home() -> void:
	clear_content()
	var bg := ColorRect.new()
	bg.color = Color("0b1730")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-260, -420)
	box.custom_minimum_size = Vector2(520, 840)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 28)
	content.add_child(box)

	var title := Label.new()
	title.text = "UNJAM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 74)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "RESCUE RUSH"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 30)
	box.add_child(subtitle)

	var rescued := Label.new()
	rescued.text = "%d rescued  •  %d coins" % [SaveManager.data.rescued.size(), int(SaveManager.data.coins)]
	rescued.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rescued.add_theme_font_size_override("font_size", 22)
	box.add_child(rescued)

	var play := make_button("PLAY")
	play.pressed.connect(build_level_select)
	box.add_child(play)

	var collection := make_button("RESCUE GARDEN", Vector2(420, 74))
	collection.pressed.connect(build_collection)
	box.add_child(collection)

func build_level_select() -> void:
	clear_content()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 70)
	margin.add_theme_constant_override("margin_right", 70)
	margin.add_theme_constant_override("margin_top", 90)
	margin.add_theme_constant_override("margin_bottom", 90)
	content.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 24)
	margin.add_child(root)

	var header := HBoxContainer.new()
	var back := make_button("←", Vector2(100, 70))
	back.pressed.connect(build_home)
	header.add_child(back)
	var label := Label.new()
	label.text = "CHOOSE A RESCUE"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	header.add_child(label)
	root.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 22)
	scroll.add_child(grid)

	for level_number in range(1, LevelManager.get_level_count() + 1):
		var unlocked := SaveManager.is_level_unlocked(level_number)
		var stars := SaveManager.get_stars(level_number)
		var button := make_button("%02d\n%s" % [level_number, "★".repeat(stars)], Vector2(270, 130))
		button.disabled = not unlocked
		button.pressed.connect(start_level.bind(level_number))
		grid.add_child(button)

func start_level(level_number: int) -> void:
	var game_scene := load("res://scenes/Game.tscn").instantiate()
	game_scene.level_number = level_number
	game_scene.finished.connect(_on_game_finished)
	game_scene.quit_requested.connect(build_level_select)
	add_child(game_scene)
	hide()

func _on_game_finished(level_number: int) -> void:
	show()
	if LevelManager.has_level(level_number + 1):
		start_level(level_number + 1)
	else:
		build_home()

func build_collection() -> void:
	clear_content()
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-300, -500)
	box.custom_minimum_size = Vector2(600, 1000)
	box.add_theme_constant_override("separation", 22)
	content.add_child(box)
	var title := Label.new()
	title.text = "RESCUE GARDEN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	box.add_child(title)
	for rescue_id in SaveManager.data.rescued:
		var item := Label.new()
		item.text = "✦  " + String(rescue_id).capitalize()
		item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item.add_theme_font_size_override("font_size", 30)
		box.add_child(item)
	if SaveManager.data.rescued.is_empty():
		var empty := Label.new()
		empty.text = "Your garden is waiting for its first rescue."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(empty)
	var back := make_button("BACK", Vector2(420, 74))
	back.pressed.connect(build_home)
	box.add_child(back)
