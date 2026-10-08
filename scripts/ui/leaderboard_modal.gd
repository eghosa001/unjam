extends CanvasLayer

# A true modal leaderboard, available in one tap from Home and Daily.
# Never invents opponents or ranks: rows come exclusively from the backend.
const PERIODS := ["today", "week", "all"]
const GAME_IDS := ["rescue_rush", "water_sort", "block_puzzle"]
const ACCENTS := {"rescue_rush": Color("#28d58c"), "water_sort": Color("#46bafa"), "block_puzzle": Color("#c88aff")}

var _host: Control
var _period := "week"
var _game_id := "rescue_rush"
var _dark := true
var _body: VBoxContainer
var _period_buttons := {}
var _game_buttons := {}
var _game_bar: HBoxContainer
var _heading: Label
var _mine: Label
var _summary: Label
var _rows: VBoxContainer
var _scroll: ScrollContainer
var _status: Label
var _footer: Button
var _card: PanelContainer
var _deadline: Timer
var _loading := false
var _failed := false
var _ui_scale := 1.0
var _inset: MarginContainer

func configure(host: Control, dark_mode: bool, period: String = "week", game_id: String = "rescue_rush") -> void:
	_host = host
	_dark = dark_mode
	_period = period if period in PERIODS else "week"
	_game_id = game_id if game_id in GAME_IDS else "rescue_rush"

func _ready() -> void:
	layer = 120
	_build()
	CompetitionManager.snapshot_updated.connect(_on_campaign_updated)
	CompetitionManager.daily_snapshot_updated.connect(_on_daily_updated)
	_request_current()

func _exit_tree() -> void:
	if CompetitionManager.snapshot_updated.is_connected(_on_campaign_updated):
		CompetitionManager.snapshot_updated.disconnect(_on_campaign_updated)
	if CompetitionManager.daily_snapshot_updated.is_connected(_on_daily_updated):
		CompetitionManager.daily_snapshot_updated.disconnect(_on_daily_updated)
	if get_viewport().size_changed.is_connected(_fit_viewport):
		get_viewport().size_changed.disconnect(_fit_viewport)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func close() -> void:
	queue_free()

func present_period(period: String) -> void:
	if period in PERIODS:
		_set_period(period)


func _style(fill: Color, outline: Color, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style

func _label(value: String, font_size: int, tint: Color) -> Label:
	var node := Label.new()
	node.text = value
	node.clip_text = true
	node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",tint)
	return node

func _button(value: String, label: String, tint: Color, callback: Callable) -> Button:
	var node := Button.new()
	node.name = value
	# Exact authored modal dimensions must survive every generic UI re-skin and
	# touch-enhancer traversal, not only the initial node-added callback.
	node.set_meta("unjam_figma_exact_geometry",true)
	node.set_meta("unjam_preserve_surface_style",true)
	node.text = label
	node.clip_text = true
	node.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	node.focus_mode = Control.FOCUS_ALL
	node.custom_minimum_size = Vector2(0,48)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size",14)
	node.add_theme_color_override("font_color",Color.WHITE)
	node.add_theme_color_override("font_focus_color",Color.WHITE)
	node.add_theme_stylebox_override("normal",_style(tint,tint.lightened(0.2),12))
	node.add_theme_stylebox_override("hover",_style(tint.lightened(0.12),tint.lightened(0.28),12))
	node.add_theme_stylebox_override("pressed",_style(tint.darkened(0.18),tint,12))
	node.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,Color("#ffda62"),12))
	node.tooltip_text = label
	node.accessibility_name = label
	node.pressed.connect(callback)
	return node

func _build() -> void:
	var overlay := Control.new()
	overlay.name = "LeaderboardModalOverlay"
	# UiTouchEnhancer must not inflate our authored 48px tabs into 88px+
	# gameplay buttons. Keep focus and touch geometry intact on compact phones.
	overlay.set_meta("unjam_preserve_control_geometry", true)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var shade := ColorRect.new()
	shade.name = "LeaderboardModalDim"
	shade.color = Color(0.025,0.035,0.070,0.86)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var center := CenterContainer.new()
	center.name = "LeaderboardModalCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(center)

	_card = PanelContainer.new()
	_card.name = "LeaderboardModalCard"
	var card_color := Color("#202630") if _dark else Color("#fbf8f1")
	_card.add_theme_stylebox_override("panel",_style(card_color,Color("#7861ac") if _dark else Color("#ad91e0"),22))
	center.add_child(_card)

	_inset = MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		_inset.add_theme_constant_override("margin_%s" % side,18)
	_card.add_child(_inset)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation",11)
	_inset.add_child(_body)
	var fg := Color("#f6f4fc") if _dark else Color("#253040")
	var muted := Color("#b6c1d0") if _dark else Color("#52606f")

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation",8)
	_body.add_child(header)
	_heading = _label("LEADERBOARDS",24,fg)
	_heading.name = "LeaderboardModalTitle"
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_heading.accessibility_name = "UNJAM player leaderboards"
	header.add_child(_heading)
	var close_button := _button("LeaderboardClose","✕ CLOSE",Color("#59546e"),Callable(self,"close"))
	close_button.custom_minimum_size = Vector2(94,48)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	header.add_child(close_button)
	close_button.grab_focus.call_deferred()

	_summary = _label("Compete with real players",13,muted)
	_summary.name = "LeaderboardModalDescription"
	_body.add_child(_summary)

	var periods := HBoxContainer.new()
	periods.name = "LeaderboardPeriodTabs"
	periods.add_theme_constant_override("separation",8)
	_body.add_child(periods)
	for entry in [["today","TODAY"],["week","WEEKLY"],["all","ALL-TIME"]]:
		var id := String(entry[0])
		var button := _button("LeaderboardPeriod_%s" % id,String(entry[1]),Color("#514c66"),Callable(self,"_set_period").bind(id))
		periods.add_child(button)
		_period_buttons[id] = button

	_game_bar = HBoxContainer.new()
	_game_bar.name = "LeaderboardGameTabs"
	_game_bar.add_theme_constant_override("separation",8)
	_body.add_child(_game_bar)
	for entry in [["rescue_rush","RESCUE"],["water_sort","WATER"],["block_puzzle","BLOCK"]]:
		var id := String(entry[0])
		var button := _button("LeaderboardGame_%s" % id,String(entry[1]),Color("#424b58"),Callable(self,"_set_game").bind(id))
		_game_bar.add_child(button)
		_game_buttons[id] = button

	_mine = _label("YOUR RANK • —",15,Color("#f0c95d") if _dark else Color("#755212"))
	_mine.name = "LeaderboardOwnRank"
	_mine.custom_minimum_size.y = 28
	_mine.accessibility_name = "Your current leaderboard rank"
	_body.add_child(_mine)

	_scroll = ScrollContainer.new()
	var scroll := _scroll
	scroll.name = "LeaderboardPlayerScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 145
	_body.add_child(scroll)

	_rows = VBoxContainer.new()
	_rows.name = "LeaderboardPlayerRows"
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation",6)
	scroll.add_child(_rows)

	_status = _label("",12,muted)
	_status.name = "LeaderboardModalStatus"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.custom_minimum_size.y = 22
	_body.add_child(_status)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",8)
	_body.add_child(actions)
	var retry := _button("LeaderboardRetry","↻ RETRY",Color("#42617c"),Callable(self,"_request_current"))
	retry.accessibility_name = "Refresh leaderboard"
	actions.add_child(retry)
	_footer = _button("LeaderboardPlay","PLAY DAILY",Color("#7659d4"),Callable(self,"_open_destination"))
	actions.add_child(_footer)

	_deadline = Timer.new()
	_deadline.name = "LeaderboardRequestDeadline"
	_deadline.one_shot = true
	_deadline.wait_time = 14.0
	_deadline.timeout.connect(_on_request_timeout)
	add_child(_deadline)
	get_viewport().size_changed.connect(_fit_viewport)
	_fit_viewport()
	_render()
	# Other legacy surface skinning runs while nodes enter the tree; reassert
	# keyboard/TalkBack focus only after all authored controls are mounted.
	_restore_accessible_button_focus()
	call_deferred("_restore_accessible_button_focus")

func _restore_accessible_button_focus() -> void:
	var overlay := get_node_or_null("LeaderboardModalOverlay")
	if overlay == null:
		return
	for node in overlay.find_children("*","Button",true,false):
		if node is Button:
			var button := node as Button
			button.focus_mode = Control.FOCUS_ALL
			button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE

func _fit_viewport() -> void:
	if _card == null or not is_instance_valid(_card):
		return
	var size := get_viewport().get_visible_rect().size
	var portrait := size.y >= size.x
	var short_screen := size.y < 620.0
	# The old 540x790 cap made rankings appear as a tiny card on 1080px
	# Android layouts. Occupy almost the entire portrait viewport while keeping
	# real safe margins and a compact centered panel on wide tablets.
	var width := minf(size.x - 24.0, size.x * 0.95)
	var height := minf(size.y - 24.0, size.y * 0.94)
	if not portrait:
		width = minf(width, size.y * 1.08)
	_ui_scale = clampf(minf(width / 510.0, height / 880.0), 0.85, 2.0)
	_card.custom_minimum_size = Vector2(maxf(220.0,width),maxf(250.0,height))
	_body.add_theme_constant_override("separation",int(9.0 * _ui_scale) if not short_screen else 5)
	_game_bar.add_theme_constant_override("separation",int(7.0 * _ui_scale))
	if _inset != null:
		for side in ["left","right","top","bottom"]:
			_inset.add_theme_constant_override("margin_%s" % side,int(14.0 * _ui_scale))
	if _scroll != null:
		_scroll.custom_minimum_size.y = maxf(60.0,96.0*_ui_scale)
	for button_id in ["LeaderboardClose","LeaderboardRetry","LeaderboardPlay"]:
		var button := _card.find_child(button_id,true,false) as Button
		if button != null:
			_scale_button(button,14)
	for button in _period_buttons.values():
		_scale_button(button as Button,14)
	for button in _game_buttons.values():
		_scale_button(button as Button,14)
	_scale_label(_heading,23)
	_scale_label(_summary,13)
	_scale_label(_mine,17)
	_scale_label(_status,12)
	if _rows != null:
		_render()

func _scale_button(button: Button, baseline: int) -> void:
	if button == null:
		return
	button.add_theme_font_size_override("font_size",int(baseline*_ui_scale))
	button.custom_minimum_size.y = 48.0*_ui_scale
	button.focus_mode = Control.FOCUS_ALL

func _scale_label(label: Label, baseline: int) -> void:
	if label != null:
		label.add_theme_font_size_override("font_size",int(baseline*_ui_scale))


func _set_period(period: String) -> void:
	if period not in PERIODS or period == _period:
		return
	_period = period
	_failed = false
	_request_current()

func _set_game(game_id: String) -> void:
	if game_id not in GAME_IDS or game_id == _game_id:
		return
	_game_id = game_id
	_render()

func _request_current() -> void:
	_loading = true
	_failed = false
	_deadline.start()
	if _period == "today":
		CompetitionManager.refresh_daily_snapshot()
	else:
		CompetitionManager.refresh_snapshot()
	_render()

func _on_campaign_updated(_snapshot: Dictionary) -> void:
	if _period == "today":
		return
	_loading = false
	_failed = false
	_deadline.stop()
	_render()

func _on_daily_updated(value: Dictionary) -> void:
	if _period != "today":
		return
	_loading = false
	_failed = value.is_empty()
	_deadline.stop()
	_render()

func _on_request_timeout() -> void:
	_loading = false
	_failed = true
	_render()

func _render() -> void:
	if _rows == null:
		return
	var today := _period == "today"
	_game_bar.visible = not today
	for id in PERIODS:
		var button := _period_buttons[id] as Button
		var selected: bool = id == _period
		button.accessibility_name = ("%s rankings, selected" if selected else "%s rankings") % button.text.capitalize()
		button.add_theme_stylebox_override("normal",_style(Color("#7056cf") if selected else Color("#454a58"),Color("#9280da") if selected else Color("#606575"),12))
	for id in GAME_IDS:
		var button := _game_buttons[id] as Button
		var accent: Color = ACCENTS[id]
		button.accessibility_name = ("%s ranking, selected" if _game_id == id else "%s ranking") % button.text.capitalize()
		button.add_theme_stylebox_override("normal",_style(accent.darkened(0.43) if _game_id == id else Color("#424955"),accent if _game_id == id else Color("#606575"),12))
	var accent_color := Color("#f0c95d") if today else ACCENTS[_game_id] as Color
	_summary.text = "Today's 3 Daily puzzles • combined scores" if today else ("New campaign levels this week" if _period == "week" else "Total campaign levels cleared")
	_footer.text = "PLAY DAILY" if today else "RANKING DETAILS"
	_footer.accessibility_name = _footer.text

	var entries: Array = []
	var own_rank := 0
	var own_score := 0
	if today:
		entries = CompetitionManager.daily_top()
		own_rank = CompetitionManager.daily_rank()
		own_score = CompetitionManager.daily_score()
	else:
		entries = CompetitionManager.game_weekly_top(_game_id) if _period == "week" else CompetitionManager.game_all_time_top(_game_id)
		own_rank = CompetitionManager.game_weekly_rank(_game_id) if _period == "week" else CompetitionManager.game_all_time_rank(_game_id)
		own_score = CompetitionManager.game_weekly_levels(_game_id) if _period == "week" else CompetitionManager.game_all_time_levels(_game_id)
	_mine.text = "YOU  #%d   •   %d %s" % [own_rank,own_score,"PTS" if today else "LEVELS"] if own_rank > 0 else "YOU  —  PLAY TO ENTER"
	_mine.accessibility_name = "Your rank is %d with %d %s" % [own_rank,own_score,"points" if today else "levels completed"] if own_rank > 0 else "You are currently unranked. Complete a challenge or campaign level to join."
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()

	for i in range(mini(entries.size(),20)):
		var row = entries[i]
		if not row is Dictionary:
			continue
		var name_text := String(row.get("name","PLAYER")).left(30)
		var score := maxi(0,int(row.get("score",0))) if today else maxi(0,int(row.get("levels_completed",0)))
		var suffix := "PTS" if today else "LVL"
		var panel := PanelContainer.new()
		panel.name = "LeaderboardPlayer_%d" % (i+1)
		panel.custom_minimum_size.y = 57*_ui_scale
		panel.add_theme_stylebox_override("panel",_style(Color("#303747") if _dark else Color("#f0edf6"),Color(accent_color,0.35),12))
		_rows.add_child(panel)
		var row_margin := MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left",int(12*_ui_scale))
		row_margin.add_theme_constant_override("margin_right",int(12*_ui_scale))
		panel.add_child(row_margin)
		var lane := HBoxContainer.new()
		lane.add_theme_constant_override("separation",int(10*_ui_scale))
		row_margin.add_child(lane)
		var place := _label("#%d" % (i+1),int(16*_ui_scale),accent_color)
		place.custom_minimum_size.x = 43*_ui_scale
		lane.add_child(place)
		var player := _label(name_text,int(16*_ui_scale),Color("#f6f4fc") if _dark else Color("#253040"))
		player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lane.add_child(player)
		var points := _label("%d %s" % [score,suffix],int(14*_ui_scale),Color("#c1d1de") if _dark else Color("#576472"))
		points.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		points.custom_minimum_size.x = 93*_ui_scale
		lane.add_child(points)
		panel.accessibility_name = "Rank %d, %s, %d %s" % [i+1,name_text,score,suffix]
		player.accessibility_name = panel.accessibility_name
	if entries.is_empty():
		var empty := _label("No scores yet. Be the first to play!" if today else "No campaign entries yet. Finish levels to join.",int(15*_ui_scale),Color("#bdc8d7") if _dark else Color("#47556c"))
		empty.name = "LeaderboardEmptyState"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size.y = 100*_ui_scale
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_rows.add_child(empty)
	_status.text = "Connection unavailable • retry" if _failed else ("Refreshing live results…" if _loading else "Live rankings • scroll to view up to 20 players")
	_status.accessibility_name = _status.text

func _open_destination() -> void:
	if _host == null or not is_instance_valid(_host):
		close()
		return
	var destination := "build_daily_games" if _period == "today" else "build_compete_leaderboard"
	var host := _host
	close()
	if host.has_method(destination):
		host.call(destination)
