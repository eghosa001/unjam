extends Control

signal closed

func _ready() -> void:
	RetentionManager.ensure_state()
	RetentionManager.retention_updated.connect(refresh)
	refresh()

func style_box(color: Color, radius: int = 24, border: Color = Color.TRANSPARENT, width: int = 0, shadow: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	for key in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		s.set(key, radius)
	if width > 0:
		s.border_width_left = width
		s.border_width_right = width
		s.border_width_top = width
		s.border_width_bottom = width
		s.border_color = border
	if shadow > 0:
		s.shadow_color = Color(0,0,0,0.28)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, 6)
	return s

func make_button(text_value: String, accent: bool = false) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = Vector2(0, 74)
	b.add_theme_font_size_override("font_size", 21)
	var c: Color = Color("223a60") if not accent else Color("20c9aa")
	b.add_theme_stylebox_override("normal", style_box(Color(c,0.94), 20, Color(1,1,1,0.08), 2, 5))
	b.add_theme_stylebox_override("hover", style_box(c.lightened(0.08), 20, Color(1,1,1,0.18), 2, 8))
	b.add_theme_stylebox_override("pressed", style_box(c.darkened(0.12), 20, Color.WHITE, 2, 2))
	b.add_theme_stylebox_override("disabled", style_box(Color("202a3d"), 20))
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("77849a"))
	return b

func refresh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var backdrop := PremiumBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(Color("071426"), Color("2dd4b6"), 4)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_" + side, 38 if side in ["left","right"] else 42)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", style_box(Color(0.035,0.065,0.125,0.95), 26, Color(1,1,1,0.08), 2, 8))
	root.add_child(header_panel)
	var header := HBoxContainer.new()
	header_panel.add_child(header)
	var back := make_button("←  BACK")
	back.custom_minimum_size.x = 170
	back.pressed.connect(_close)
	header.add_child(back)
	var title := Label.new()
	title.text = "LIVE RESCUE HUB"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	header.add_child(title)
	var currency := Label.new()
	currency.text = "%d ◆" % int(SaveManager.data.event_currency)
	currency.custom_minimum_size.x = 150
	currency.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	currency.add_theme_font_size_override("font_size", 22)
	header.add_child(currency)

	var profile: Dictionary = RetentionManager.profile_snapshot()
	var hero := PanelContainer.new()
	hero.add_theme_stylebox_override("panel", style_box(Color(0.05,0.10,0.19,0.96), 28, Color("2dd4b6"), 2, 10))
	root.add_child(hero)
	var hero_box := VBoxContainer.new()
	hero_box.add_theme_constant_override("separation", 8)
	hero.add_child(hero_box)
	var rank := Label.new()
	rank.text = String(profile.get("title", "PLAYER")).to_upper()
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank.add_theme_font_size_override("font_size", 28)
	rank.add_theme_color_override("font_color", Color("67e8cf"))
	hero_box.add_child(rank)
	var stats := Label.new()
	stats.text = "%d PRESTIGE   •   %d AP   •   %d PERFECTS   •   %d VARIANTS" % [int(profile.get("prestige",0)), int(profile.get("achievement_points",0)), int(profile.get("perfects",0)), int(profile.get("variants",0))]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 18)
	hero_box.add_child(stats)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	scroll.add_child(body)
	build_login(body)
	build_missions(body)
	build_game_tasks(body)
	build_streak(body)
	build_weekly(body)
	build_season(body)
	build_achievements(body)
	build_event_shop(body)
	build_collection(body)
	PremiumVisuals.entrance(root, 0.02)

func section(parent: VBoxContainer, title_text: String, subtitle_text: String = "") -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style_box(Color(0.035,0.065,0.125,0.95), 26, Color(1,1,1,0.07), 2, 8))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 25)
	box.add_child(title)
	if not subtitle_text.is_empty():
		var sub := Label.new()
		sub.text = subtitle_text
		sub.modulate = Color("9cabc0")
		sub.add_theme_font_size_override("font_size", 17)
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(sub)
	return box

func build_login(parent: VBoxContainer) -> void:
	var box := section(parent, "7-DAY RESCUE REWARDS", "Return each day to grow the reward cycle.")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var day: int = clampi(int(SaveManager.data.login_cycle_day), 1, 7)
	for i in range(7):
		var label := Label.new()
		label.text = "D%d\n%d" % [i+1, RetentionManager.LOGIN_REWARDS[i]]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(120, 62)
		label.modulate = Color("67e8cf") if i + 1 == day else Color("8c9bb0")
		row.add_child(label)
	var claim := make_button("CLAIM TODAY'S REWARD", true)
	claim.disabled = not RetentionManager.can_claim_login_reward()
	claim.pressed.connect(func(): RetentionManager.claim_login_reward())
	box.add_child(claim)

func build_missions(parent: VBoxContainer) -> void:
	var box := section(parent, "DAILY MISSIONS", "Three fresh objectives every day. Complete all three for the Master Chest.")
	for mission in RetentionManager.daily_missions():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		box.add_child(row)
		var text := Label.new()
		var progress: int = int(RetentionManager.mission_progress(String(mission.id)))
		text.text = "%s\n%s   %d/%d" % [String(mission.title), String(mission.description), mini(progress, int(mission.target)), int(mission.target)]
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_font_size_override("font_size", 18)
		row.add_child(text)
		var claim := make_button("CLAIM")
		claim.custom_minimum_size.x = 150
		claim.disabled = progress < int(mission.target) or RetentionManager.mission_claimed(String(mission.id))
		claim.pressed.connect(func(id = String(mission.id)): RetentionManager.claim_mission(id))
		row.add_child(claim)
	var all := make_button("OPEN DAILY MASTER CHEST  •  +%d COINS" % RetentionManager.DAILY_ALL_BONUS, true)
	all.disabled = not RetentionManager.can_claim_daily_all()
	all.pressed.connect(func(): RetentionManager.claim_daily_all())
	box.add_child(all)

func build_game_tasks(parent: VBoxContainer) -> void:
	var box := section(parent, "GAME TASKS", "Campaign play advances three claimable tasks for each game every day.")
	for game_id in MultiGameManager.GAME_IDS:
		var game_label := Label.new()
		game_label.text = MultiGameManager.display_name(game_id)
		game_label.add_theme_font_size_override("font_size", 20)
		game_label.add_theme_color_override("font_color", Unjam3DTheme.game_accent(game_id))
		box.add_child(game_label)
		for task_value in MultiGameManager.daily_tasks(game_id):
			if not task_value is Dictionary:
				continue
			var task: Dictionary = task_value
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			box.add_child(row)
			var detail := Label.new()
			var progress := mini(int(task.get("progress",0)), int(task.get("target",0)))
			detail.text = "%s   %d/%d" % [String(task.get("title","TASK")), progress, int(task.get("target",0))]
			detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			detail.add_theme_font_size_override("font_size", 17)
			row.add_child(detail)
			var claimed := bool(task.get("claimed",false))
			var claim := make_button("CLAIMED" if claimed else "%d COINS • 10 AP" % MultiGameManager.TASK_REWARD, not claimed)
			claim.custom_minimum_size.x = 220
			claim.disabled = claimed or progress < int(task.get("target",0))
			claim.pressed.connect(_claim_game_task.bind(game_id, String(task.get("id",""))))
			row.add_child(claim)

func _claim_game_task(game_id: String, task_id: String) -> void:
	if MultiGameManager.claim_daily_task(game_id, task_id):
		FeedbackManager.effect()
		refresh()

func build_streak(parent: VBoxContainer) -> void:
	var current := int(SaveManager.data.win_streak)
	var best := int(SaveManager.data.best_win_streak)
	var box := section(parent, "WIN-STREAK RUSH", "Consecutive campaign rescues unlock escalating bonus chests.")
	var label := Label.new()
	label.text = "CURRENT  %d   •   BEST  %d   •   CHESTS AT 3 / 5 / 10 / 15 / 25" % [current, best]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 19)
	box.add_child(label)

func build_weekly(parent: VBoxContainer) -> void:
	var rank: int = int(RetentionManager.weekly_rank())
	var points := int(SaveManager.data.weekly_points)
	var box := section(parent, "WEEKLY RESCUE LEAGUE", "Seeded offline rivals keep the ladder active now; the scoring layer is ready for a backend leaderboard later.")
	var headline := Label.new()
	headline.text = "YOUR RANK  #%d   •   %d POINTS" % [rank, points]
	headline.add_theme_font_size_override("font_size", 22)
	headline.add_theme_color_override("font_color", Color("ffd166"))
	box.add_child(headline)
	var last_result = SaveManager.data.get("last_week_result", {})
	if last_result is Dictionary and not (last_result as Dictionary).is_empty():
		var previous := Label.new()
		previous.text = "LAST WEEK  •  #%d  •  %d PTS  •  +%d COINS  •  +%d PRESTIGE" % [
			int((last_result as Dictionary).get("rank",0)),
			int((last_result as Dictionary).get("points",0)),
			int((last_result as Dictionary).get("coins",0)),
			int((last_result as Dictionary).get("prestige",0))
		]
		previous.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		previous.add_theme_font_size_override("font_size", 16)
		box.add_child(previous)
	var rivals: Array = RetentionManager.weekly_rivals()
	for i in range(mini(5, rivals.size())):
		var r: Dictionary = rivals[i]
		var line := Label.new()
		line.text = "#%d  %-12s  %d" % [i+1, String(r.get("name","RIVAL")), int(r.get("points",0))]
		line.add_theme_font_size_override("font_size", 17)
		box.add_child(line)
	for i in range(RetentionManager.WEEKLY_TARGETS.size()):
		var claim := make_button("%d PTS  •  %d COINS" % [RetentionManager.WEEKLY_TARGETS[i], RetentionManager.WEEKLY_REWARDS[i]])
		claim.disabled = points < RetentionManager.WEEKLY_TARGETS[i] or str(i) in SaveManager.data.weekly_claimed_tiers
		claim.pressed.connect(func(idx = i): RetentionManager.claim_weekly_tier(idx))
		box.add_child(claim)

func build_season(parent: VBoxContainer) -> void:
	var points := int(SaveManager.data.season_points)
	var box := section(parent, "SEASON JOURNEY", "A two-month free progression track with coins and event currency.")
	var headline := Label.new()
	headline.text = "SEASON SCORE  %d" % points
	headline.add_theme_font_size_override("font_size", 22)
	box.add_child(headline)
	for i in range(RetentionManager.SEASON_TARGETS.size()):
		var claim := make_button("TIER %d  •  %d PTS  •  %d COINS" % [i+1, RetentionManager.SEASON_TARGETS[i], RetentionManager.SEASON_REWARDS[i]])
		claim.disabled = points < RetentionManager.SEASON_TARGETS[i] or str(i) in SaveManager.data.season_claimed_tiers
		claim.pressed.connect(func(idx = i): RetentionManager.claim_season_tier(idx))
		box.add_child(claim)

func build_achievements(parent: VBoxContainer) -> void:
	var box := section(parent, "ACHIEVEMENT VAULT", "Major accomplishments unlock claimable coin rewards in addition to prestige and achievement points.")
	for id in RetentionManager.ACHIEVEMENT_REWARDS:
		var reward: Dictionary = RetentionManager.ACHIEVEMENT_REWARDS[id]
		var unlocked: bool = id in SaveManager.data.achievements
		var claimed: bool = id in SaveManager.data.achievement_reward_claimed
		var b := make_button("%s  •  %d COINS%s" % [String(reward.get("title","ACHIEVEMENT")), int(reward.get("coins",0)), "  CLAIMED" if claimed else ("  LOCKED" if not unlocked else "")], unlocked and not claimed)
		b.disabled = not unlocked or claimed
		b.pressed.connect(func(key = String(id)): RetentionManager.claim_achievement_reward(key))
		box.add_child(b)

func build_event_shop(parent: VBoxContainer) -> void:
	var box := section(parent, "LIMITED EVENT SHOP", "Earn ◆ from missions and campaign play. Purchased cosmetics apply automatically.")
	var cap := int(RetentionManager.EVENT_DAILY_CAP) if "EVENT_DAILY_CAP" in RetentionManager else 80
	var earned_today := int(SaveManager.data.get("event_daily_earned",0))
	var cap_label := Label.new()
	cap_label.text = "TODAY'S EVENT EARNINGS  •  %d/%d ◆" % [earned_today, cap]
	cap_label.add_theme_font_size_override("font_size", 16)
	box.add_child(cap_label)
	for item in RetentionManager.event_shop():
		var owned: bool = String(item.id) in SaveManager.data.event_shop_owned
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		box.add_child(row)
		var detail := Label.new()
		detail.text = "%s\n%s" % [String(item.title), String(item.get("effect","Cosmetic reward"))]
		detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_font_size_override("font_size", 17)
		row.add_child(detail)
		var b := make_button("ACTIVE" if owned else "%d ◆" % int(item.cost), owned)
		b.custom_minimum_size.x = 150
		b.disabled = owned or int(SaveManager.data.event_currency) < int(item.cost)
		b.pressed.connect(func(id = String(item.id)): RetentionManager.buy_event_item(id))
		row.add_child(b)

func build_collection(parent: VBoxContainer) -> void:
	var box := section(parent, "RESCUE COLLECTION", "Your rescued friends and milestone variants live here. Highest unlocked rarity applies automatically in Rescue Rush.")
	var rescued: Array = SaveManager.data.get("rescued", [])
	var friends := Label.new()
	friends.text = "FRIENDS HOME  •  NONE YET" if rescued.is_empty() else "FRIENDS HOME  •  %s" % "  •  ".join(rescued)
	friends.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	friends.add_theme_font_size_override("font_size", 18)
	box.add_child(friends)
	var variants: Array = SaveManager.data.rescue_variants
	var text := Label.new()
	text.text = "VARIANTS  •  NONE YET" if variants.is_empty() else "VARIANTS  •  %s" % "  •  ".join(variants)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 18)
	box.add_child(text)

func _close() -> void:
	closed.emit()
	queue_free()
