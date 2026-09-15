extends Node

var signature := ""
var timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_refresh")

func _process(delta: float) -> void:
	timer += delta
	if timer < 0.22:
		return
	timer = 0.0
	_refresh()

func _refresh() -> void:
	var main := get_parent()
	if main == null:
		return
	var surface := String(main.get("current_surface")) if main.get("current_surface") != null else "home"
	if surface not in ["settings", "collection"]:
		signature = ""
		return
	var content: Control = main.get("content") as Control
	if content == null or not is_instance_valid(content):
		return
	var shell := main.get_node_or_null("UXShell")
	var dark := shell == null or String(shell.get("theme_mode")) != "light"
	var new_signature := "%s|%s|%d" % [surface, "dark" if dark else "light", content.get_instance_id()]
	if new_signature == signature:
		return
	signature = new_signature
	var old: Node = content.get_node_or_null("PremiumMiddleFill")
	if old != null:
		old.queue_free()
	var layer := Control.new()
	layer.name = "PremiumMiddleFill"
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = 1
	content.add_child(layer)
	if surface == "settings":
		_build_settings_fill(layer, dark)
	else:
		_build_collection_fill(layer, dark)

func _build_settings_fill(layer: Control, dark: bool) -> void:
	var accent := PremiumDesignSystem.accent_for_game("rescue_rush")
	var panel := PanelContainer.new()
	panel.anchor_left = 0.04
	panel.anchor_right = 0.96
	panel.anchor_top = 0.34
	panel.anchor_bottom = 0.72
	panel.add_theme_stylebox_override("panel", PremiumDesignSystem.box(Color(PremiumDesignSystem.surface(dark), 0.98), 32, Color(accent, 0.28), 1, 8, dark))
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 28)
	panel.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 20)
	margin.add_child(root)
	var eyebrow := _label("YOUR UNJAM PROFILE", 18, PremiumDesignSystem.muted(dark))
	root.add_child(eyebrow)
	var title := _label("THREE GAMES. ONE RHYTHM.", 30, PremiumDesignSystem.ink(dark))
	root.add_child(title)
	var copy := _label("Each game keeps its own campaign while sharing your overall progression and feel settings.", 18, PremiumDesignSystem.muted(dark))
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(copy)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		var game_accent := PremiumDesignSystem.accent_for_game(game_id)
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(300, 250)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", PremiumDesignSystem.box(PremiumDesignSystem.surface_2(dark), 26, Color(game_accent, 0.46), 2, 5, dark))
		row.add_child(card)
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 10)
		card.add_child(box)
		var game_title := _label(MultiGameManager.display_name(game_id).to_upper(), 21, game_accent)
		game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(game_title)
		var progress := MultiGameManager.progress_for(game_id)
		var level := mini(10000, int(progress.get("highest_level", 1)))
		var level_label := _label("LEVEL %d / 10,000" % level, 18, PremiumDesignSystem.ink(dark))
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(level_label)
		var world_label := _label("WORLD %d / 100" % MultiGameManager.highest_unlocked_world(game_id), 16, PremiumDesignSystem.muted(dark))
		world_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(world_label)
		var bar := ProgressBar.new()
		bar.max_value = 10000.0
		bar.value = float(level)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(220, 14)
		bar.add_theme_stylebox_override("background", PremiumDesignSystem.box(PremiumDesignSystem.surface_3(dark), 7, Color.TRANSPARENT, 0, 0, dark))
		bar.add_theme_stylebox_override("fill", PremiumDesignSystem.box(game_accent, 7, game_accent.lightened(0.12), 1, 0, dark))
		box.add_child(bar)

func _build_collection_fill(layer: Control, dark: bool) -> void:
	var accent := PremiumDesignSystem.accent_for_game("rescue_rush")
	var panel := PanelContainer.new()
	panel.anchor_left = 0.04
	panel.anchor_right = 0.96
	panel.anchor_top = 0.50
	panel.anchor_bottom = 0.82
	panel.add_theme_stylebox_override("panel", PremiumDesignSystem.box(Color(PremiumDesignSystem.surface(dark), 0.96), 32, Color(accent, 0.28), 1, 8, dark))
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 28)
	panel.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)
	var heading := HBoxContainer.new()
	root.add_child(heading)
	var title := _label("SANCTUARY MOMENTS", 26, PremiumDesignSystem.ink(dark))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(_label("Your rescued crew grows here", 16, PremiumDesignSystem.muted(dark)))
	var rescued: Array = SaveManager.data.rescued
	var slots := HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("separation", 14)
	slots.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(slots)
	for i in range(4):
		var filled: bool = i < rescued.size()
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(210, 230)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", PremiumDesignSystem.box(PremiumDesignSystem.surface_2(dark), 26, Color(accent, 0.45 if filled else 0.18), 2 if filled else 1, 4, dark))
		slots.add_child(card)
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 10)
		card.add_child(box)
		var icon := _label("✦" if filled else "?", 42, accent if filled else PremiumDesignSystem.muted(dark))
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(icon)
		var name_text := String(rescued[i]).capitalize() if filled else "LOCKED FRIEND"
		var name := _label(name_text.to_upper(), 17, PremiumDesignSystem.ink(dark) if filled else PremiumDesignSystem.muted(dark))
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(name)
		var state := _label("HOME" if filled else "KEEP RESCUING", 13, accent if filled else PremiumDesignSystem.muted(dark))
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(state)
	var next := _label("NEXT MILESTONE  •  Rescue more friends in Rescue Rush to bring the sanctuary to life.", 17, PremiumDesignSystem.muted(dark))
	next.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(next)

func _label(text_value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
