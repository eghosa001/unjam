extends "res://scripts/ui/premium_home_overhaul.gd"

# Reference-composed Home: fantasy waterfall world, oversized colorful branding,
# explorer sign stack, a real-time 3D mascot, one dominant PLAY action, stone
# motto and a chunky four-item bottom navigation bar.

func build_home_launcher() -> void:
	for child in get_children():
		child.queue_free()
	last_theme = _theme_mode()
	built = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := Unjam3DBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(Unjam3DTheme.GREEN)
	add_child(backdrop)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 34)
	outer.add_theme_constant_override("margin_right", 34)
	outer.add_theme_constant_override("margin_top", 28)
	outer.add_theme_constant_override("margin_bottom", 120)
	add_child(outer)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	outer.add_child(root)

	_make_status_bar(root)
	_make_brand_logo(root)
	_make_tagline(root)
	_make_hero(root)

	primary_button = Button.new()
	primary_button.name = "HomePrimaryAction"
	primary_button.text = "▶   PLAY"
	primary_button.custom_minimum_size = Vector2(0, 124)
	primary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary_button.add_theme_font_size_override("font_size", 45)
	Unjam3DTheme.gloss_button(primary_button, Unjam3DTheme.GREEN, true, 44)
	primary_button.pressed.connect(_open_game_selector)
	root.add_child(primary_button)

	var play_hint := Label.new()
	play_hint.text = "START THE JOURNEY   •   CHOOSE YOUR PUZZLE"
	play_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_hint.add_theme_font_size_override("font_size", 18)
	Unjam3DTheme.label_3d(play_hint, Color.WHITE, Unjam3DTheme.NAVY, 3)
	root.add_child(play_hint)

	_make_motto(root)
	_make_bottom_nav()
	_animate_entry(root)

func _make_status_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 76)
	bar.add_theme_constant_override("separation", 10)
	parent.add_child(bar)
	var cleared := 0
	for game_id in MultiGameManager.GAME_IDS:
		cleared += int(MultiGameManager.progress_for(game_id).get("levels_completed", 0))
	var player_level := maxi(1, 1 + int(cleared / 10))
	bar.add_child(_make_badge("☺  LV %d" % player_level, Unjam3DTheme.WATER))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	bar.add_child(_make_badge("●  %s  +" % _compact_number(int(SaveManager.data.get("coins", 0))), Unjam3DTheme.ORANGE))
	bar.add_child(_make_badge("★  %s  +" % _compact_number(_total_stars()), Unjam3DTheme.GOLD))

func _make_badge(text_value: String, fill: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(190, 68)
	badge.add_theme_stylebox_override("panel", Unjam3DTheme.badge(fill, 27))
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 21)
	Unjam3DTheme.label_3d(label, Color.WHITE, fill.darkened(0.46), 3)
	badge.add_child(label)
	return badge

func _make_brand_logo(parent: VBoxContainer) -> void:
	var logo_box := VBoxContainer.new()
	logo_box.custom_minimum_size = Vector2(0, 205)
	logo_box.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_box.add_theme_constant_override("separation", -2)
	parent.add_child(logo_box)
	var letters := HBoxContainer.new()
	letters.alignment = BoxContainer.ALIGNMENT_CENTER
	letters.add_theme_constant_override("separation", -13)
	logo_box.add_child(letters)
	var palette := [Color("ffd52b"), Color("ff8c21"), Color("ff4b83"), Color("ce48ff"), Color("25b7ff")]
	var text := "UNJAM"
	for i in range(text.length()):
		var label := Label.new()
		label.text = text.substr(i, 1)
		label.add_theme_font_size_override("font_size", 120)
		label.custom_minimum_size = Vector2(148, 142)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.rotation = deg_to_rad(float(i - 2) * 1.7)
		label.position.y = absf(float(i - 2)) * 4.0
		Unjam3DTheme.label_3d(label, palette[i], Color("06488d"), 11)
		letters.add_child(label)
	var subtitle := Label.new()
	subtitle.text = "THREE PUZZLES  •  ONE JOURNEY"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	Unjam3DTheme.label_3d(subtitle, Color.WHITE, Unjam3DTheme.NAVY, 4)
	logo_box.add_child(subtitle)

func _make_tagline(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)
	var plaque := PanelContainer.new()
	plaque.custom_minimum_size = Vector2(650, 64)
	plaque.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("ae592d"), 25, Color("f1ac5f"), 3, 8))
	center.add_child(plaque)
	var label := Label.new()
	label.text = "PUZZLE  •  RELAX  •  BRIGHTER DAYS ♥"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 19)
	Unjam3DTheme.label_3d(label, Color.WHITE, Color("6f2e14"), 3)
	plaque.add_child(label)

func _make_hero(parent: VBoxContainer) -> void:
	var hero := PanelContainer.new()
	hero.name = "HomeHero3D"
	hero.custom_minimum_size = Vector2(0, 540)
	hero.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(0.82, 0.97, 1.0, 0.12), 42, Color(1, 1, 1, 0.44), 2, 8))
	parent.add_child(hero)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	hero.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	_make_sign_stack(row)

	var mascot := Unjam3DMascot.new()
	mascot.name = "HomeMascot3D"
	mascot.custom_minimum_size = Vector2(470, 500)
	mascot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mascot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(mascot)

	var message_panel := PanelContainer.new()
	message_panel.custom_minimum_size = Vector2(245, 300)
	message_panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(1.0, 0.98, 0.82, 0.72), 34, Color("fff1a1"), 2, 6))
	row.add_child(message_panel)
	var message := Label.new()
	message.text = "Small\nPuzzles\n\nBrighter\nDays ♥"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 29)
	Unjam3DTheme.label_3d(message, Color("21438d"), Color.WHITE, 2)
	message_panel.add_child(message)

func _make_sign_stack(parent: HBoxContainer) -> void:
	var stack := VBoxContainer.new()
	stack.name = "ExplorerSignStack"
	stack.custom_minimum_size = Vector2(235, 340)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 7)
	parent.add_child(stack)
	for item in ["PUZZLE", "RELAX", "BRIGHTER", "DAYS ♥"]:
		var sign := PanelContainer.new()
		sign.custom_minimum_size = Vector2(220, 68)
		sign.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("b56832"), 13, Color("efaa58"), 2, 6))
		stack.add_child(sign)
		var label := Label.new()
		label.text = String(item)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		Unjam3DTheme.label_3d(label, Color("5b2513"), Color("ffd394"), 2)
		sign.add_child(label)

func _make_motto(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)
	var stone := PanelContainer.new()
	stone.name = "HomeMottoStone"
	stone.custom_minimum_size = Vector2(620, 96)
	stone.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("c8c4a7"), 30, Color("eef0cf"), 3, 8))
	center.add_child(stone)
	var label := Label.new()
	label.text = "Good puzzles\nbrighter people.  ♥"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	Unjam3DTheme.label_3d(label, Color("244279"), Color(1,1,1,0.82), 2)
	stone.add_child(label)

func _make_bottom_nav() -> void:
	var nav := PanelContainer.new()
	nav.name = "HomeBottomNav3D"
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_left = 28
	nav.offset_right = -28
	nav.offset_top = -108
	nav.offset_bottom = -16
	nav.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("0756a8"), 30, Color("56c8ff"), 3, 10))
	add_child(nav)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	nav.add_child(row)
	var entries: Array = [
		["⌂\nHOME", Callable()],
		["★\nLEVELS", Callable(self, "_open_journey")],
		["♥\nCOLLECTION", func(): get_parent().call("build_collection")],
		["⚙\nSETTINGS", func(): get_parent().call("build_settings")]
	]
	for i in range(entries.size()):
		var entry: Array = entries[i]
		var button := Button.new()
		button.text = String(entry[0])
		button.custom_minimum_size = Vector2(0, 78)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		Unjam3DTheme.gloss_button(button, Unjam3DTheme.WATER if i == 0 else Color("0d6dc2"), i == 0, 22)
		var callback: Callable = entry[1]
		if callback.is_valid():
			button.pressed.connect(callback)
		row.add_child(button)

func _open_game_selector() -> void:
	var main := get_parent()
	if main == null:
		return
	FeedbackManager.tap()
	main.set("current_surface", "live")
	var content = main.get("content")
	if content is Control and is_instance_valid(content):
		(content as Control).hide()

func _animate_entry(root: Control) -> void:
	if MotionSystem.reduced():
		root.modulate = Color.WHITE
		return
	root.modulate.a = 0.72
	root.position.y = 18.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "modulate:a", 1.0, 0.20)
	tween.parallel().tween_property(root, "position:y", 0.0, 0.28)

func _compact_number(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (float(value) / 1000000.0)
	if value >= 1000:
		return "%.1fK" % (float(value) / 1000.0)
	return str(value)
