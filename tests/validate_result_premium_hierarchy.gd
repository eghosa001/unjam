extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var overlay := PremiumResultOverlay.new()
	overlay.configure(
		"RESCUE COMPLETE",
		"Rescue secured. The path is clear.",
		"9 MOVES • +75 COINS\n3★: 0 ERRORS • NO HINT/UNDO • ≤ 11",
		3,
		Color("2dd4b6"),
		"NEXT RESCUE",
		"RESCUE SECURED"
	)
	overlay.configure_secondary("DOUBLE BASE REWARD",true)
	root.add_child(overlay)
	await _frames(6)

	var card := overlay.find_child("ResultCard3D",true,false) as Control
	var title := overlay.find_child("ResultTitle",true,false) as Label
	var subtitle := overlay.find_child("ResultSubtitle",true,false) as Label
	var badge := overlay.find_child("ResultBadgeText",true,false) as Label
	var primary := overlay.find_child("PrimaryAction",true,false) as Button
	var secondary := overlay.find_child("SecondaryAction",true,false) as Button
	var secondary_shadow := overlay.find_child("SecondaryActionShadow",true,false) as Control
	var stats := overlay.find_child("ResultStatsText",true,false) as Label
	var identity_art := overlay.find_child("ResultGameArt2D",true,false) as Control
	var victory_halo := overlay.find_child("ResultVictoryHalo",true,false) as Control
	var victory_rays := overlay.find_children("ResultVictoryRay_*","ColorRect",true,false)
	if card == null or title == null or subtitle == null or badge == null or primary == null or secondary == null or secondary_shadow == null or stats == null or identity_art == null or victory_halo == null:
		return _fail("Result hierarchy is incomplete")
	if victory_rays.size() < 8:
		return _fail("Result victory aura lost its lightweight ray hierarchy")
	if badge.text != "RESCUE SECURED":
		return _fail("Result status badge is missing or stale")
	if subtitle.size.y < 64.0:
		return _fail("Result subtitle lost room for multi-line reward summaries")
	if not _rect_eq(Rect2(card.position,card.size),Rect2(27,76,334,570)):
		return _fail("Result card geometry drifted")
	if not _rect_eq(Rect2(primary.position,primary.size),Rect2(47,498,294,58)):
		return _fail("Result primary geometry drifted")
	if not _rect_eq(Rect2(secondary.position,secondary.size),Rect2(47,568,294,48)):
		return _fail("Result secondary geometry drifted")
	if not secondary_shadow.visible:
		return _fail("Visible secondary action lost its shadow")
	if badge.get_rect().intersects(title.get_rect()):
		return _fail("Result status badge overlaps title")
	if title.get_rect().intersects(subtitle.get_rect()):
		return _fail("Result title overlaps subtitle")
	if subtitle.get_rect().intersects(identity_art.get_rect()):
		return _fail("Result subtitle overlaps game identity art")
	if identity_art.get_script() == null or not String(identity_art.get_script().resource_path).ends_with("unjam_2d_game_art.gd"):
		return _fail("Result identity is not using authored 2D game art")
	if not bool(identity_art.get("compact")) or identity_art.is_processing():
		return _fail("Result authored game art must remain compact and static")
	if overlay.find_child("ResultGameArt3D",true,false) != null:
		return _fail("Retired 3D result identity returned")
	var stats_panel := overlay.find_child("Stats",true,false) as Control
	var first_star := overlay.find_child("StarCard",true,false) as Control
	if first_star != null and subtitle.get_rect().intersects(first_star.get_rect()):
		return _fail("Result subtitle overlaps star row")
	if stats_panel != null and primary.get_rect().intersects(stats_panel.get_rect()):
		return _fail("Result stats overlap primary action")
	for node in overlay.find_children("StarCard","PanelContainer",true,false):
		if stats_panel != null and (node as Control).get_rect().intersects(stats_panel.get_rect()):
			return _fail("Result stars overlap stats panel")
	var earned_glows := overlay.find_children("ResultStarGlow_*","PanelContainer",true,false)
	if earned_glows.size() != 3:
		return _fail("Three-star result lost its earned-star glow hierarchy")
	if stats.text.is_empty():
		return _fail("Result stats are missing")
	# Premium result actions must not run twice from rapid double taps.
	# A paid/rewarded secondary action only re-arms on explicit retry.
	var emitted := {"primary":0, "secondary":0}
	overlay.continue_requested.connect(func(): emitted["primary"] += 1)
	overlay.secondary_requested.connect(func(): emitted["secondary"] += 1)
	secondary.pressed.emit()
	secondary.pressed.emit()
	if int(emitted["secondary"]) != 1 or not secondary.disabled:
		return _fail("Rewarded-result action started more than one concurrent ad")
	overlay.set_secondary_state("DOUBLE BASE REWARD",true,"Try again")
	if secondary.disabled:
		return _fail("Explicit rewarded-ad retry could not re-enable the button")
	secondary.pressed.emit()
	secondary.pressed.emit()
	if int(emitted["secondary"]) != 2 or not secondary.disabled:
		return _fail("Ad retry did not remain single-flight")
	primary.pressed.emit()
	primary.pressed.emit()
	secondary.pressed.emit()
	if int(emitted["primary"]) != 1 or int(emitted["secondary"]) != 2:
		return _fail("Double-tapping Continue/Reward caused duplicate win/navigation signals")
	if not primary.disabled:
		return _fail("Result Continue remained tappable after winning transition")

	overlay.queue_free()
	await _frames(2)

	var block_result := PremiumResultOverlay.new()
	block_result.configure(
		"BLOCK PUZZLE COMPLETE",
		"Strong placements. Clean lines. Space controlled.",
		"SCORE 640 • 4 LINES\n7 PLACEMENTS",
		3,
		Color("8b7cf6"),
		"NEXT PUZZLE"
	)
	root.add_child(block_result)
	await _frames(5)
	var block_card := block_result.find_child("ResultCard3D",true,false) as Control
	var block_title := block_result.find_child("ResultTitle",true,false) as Label
	var block_subtitle := block_result.find_child("ResultSubtitle",true,false) as Label
	var hidden_secondary := block_result.find_child("SecondaryAction",true,false) as Button
	var hidden_shadow := block_result.find_child("SecondaryActionShadow",true,false) as Control
	if block_card == null or block_title == null or block_subtitle == null or hidden_secondary == null or hidden_shadow == null:
		return _fail("Block result hierarchy is incomplete")
	if block_title.text != "BLOCK PUZZLE":
		return _fail("Result title redundantly includes completion text: %s" % block_title.text)
	if block_title.autowrap_mode != TextServer.AUTOWRAP_OFF:
		return _fail("Result title can still wrap into the subtitle")
	if block_title.get_rect().intersects(block_subtitle.get_rect()):
		return _fail("Block result title geometry overlaps subtitle")
	if not _rect_eq(Rect2(block_card.position,block_card.size),Rect2(27,76,334,500)):
		return _fail("Result without secondary action did not collapse its empty slot")
	if hidden_secondary.visible or hidden_shadow.visible:
		return _fail("Hidden secondary result action still leaves a visible placeholder")

	block_result.queue_free()
	await process_frame
	print("Result hierarchy validated without collisions or empty action slots.")
	quit(0)

func _rect_eq(actual: Rect2, expected: Rect2) -> bool:
	return actual.position.distance_to(expected.position) <= 1.0 and actual.size.distance_to(expected.size) <= 1.0

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
