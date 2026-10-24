extends SceneTree
# Checks the real secondary-screen information architecture rather than
# rewarding an arbitrary count of controls on the screenshot.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT","1")
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if not _check(packed != null,"Main scene missing"):return
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(6)

	main.call("build_daily_games")
	var goals := main.find_child("DailyGoalsOpen",true,false) as Button
	var ranks := main.find_child("DailyLeaderboardOpen",true,false) as Button
	if not _check(goals != null and ranks != null,"Daily must expose Goals and Rankings as peer 48px buttons"):return
	if not _check(goals.size.y >= 44 and ranks.size.y >= 44 and not goals.get_global_rect().intersects(ranks.get_global_rect()),"Daily navigation shortcuts overlap or have small targets"):return
	goals.pressed.emit()
	if not _check(String(main.get("current_surface")) == "goals","Daily Goals shortcut did not open Goals"):return
	if not _check(String(main.get("_goals_return_surface")) == "daily","Goals lost its Daily origin"):return
	var daily_actions := _goal_action_count(main,"daily")
	var weekly_actions := _goal_action_count(main,"weekly")
	if not _check(daily_actions == 3 and weekly_actions == 0,"Goals daily focus shows %d Daily and %d Weekly actions" % [daily_actions,weekly_actions]):return
	if not _check(main.find_child("GoalsSeason",true,false) != null and main.find_child("GoalsLogin",true,false) != null,"Goals must always show season and check-in"):return
	var weekly: Button
	for node in main.find_children("*","Button",true,false):
		var name_value := String(node.name).to_lower()
		if name_value.begins_with("goalsperiod") and name_value.contains("weekly"):
			weekly = node as Button
			break
	if not _check(weekly != null and weekly.size.y >= 44 and weekly.accessibility_name.contains("Weekly"),"Weekly missions are inaccessible"):return
	weekly.pressed.emit()
	if not _check(String(main.get("_goals_focus")) == "weekly","Weekly focus tap failed"):return
	if not _check(_goal_action_count(main,"weekly") == 3 and _goal_action_count(main,"daily") == 0,"Weekly view fails to declutter or hides missions"):return
	var guide := main.find_child("GoalsRewardGuideText",true,false) as Label
	if not _check(guide != null and guide.text.contains("coins") and guide.text.contains("Season"),"Goals does not distinguish reward currencies"):return
	main.call("_return_from_goals")
	if not _check(String(main.get("current_surface")) == "daily","Goals Back lost the actual Daily parent"):return
	main.call("build_goals")
	if not _check(String(main.get("_goals_focus")) == "weekly","Goals reopening lost the chosen period"):return
	main.call("build_collection")
	main.call("build_profile")
	main.call("_return_from_profile")
	if not _check(String(main.get("current_surface")) == "collection","Profile Back did not return to Collection"):return
	main.call("build_compete_leaderboard",false)
	main.call("build_friends",false)
	main.call("_return_from_friends")
	if not _check(String(main.get("current_surface")) == "compete","Friends Back skipped Rankings"):return
	main.call("build_friends",false)
	main.call("build_compete_leaderboard",false)
	main.call("_return_from_compete")
	if not _check(String(main.get("current_surface")) == "friends","Rankings Back skipped Friends"):return
	var empty := main.find_child("FriendsEmptyTitle",true,false) as Label
	if empty != null:
		var invite := main.find_child("FriendsEmptyCopyAction",true,false) as Button
		if not _check(invite != null and invite.size.y >= 44 and invite.accessibility_name.contains("friend code"),"Empty Friends view lacks its invite action"):return
	main.queue_free()
	await _frames(3)
	print("NAVIGATION_HIERARCHY_DENSITY_OK focused missions, reward discovery, contextual Back, and informative empty state")
	quit(0)

# Godot sanitizes slash-separated authored control names to underscores.
func _goal_action_count(main: Control, period: String) -> int:
	var count := 0
	for node in main.find_children("*","Button",true,false):
		var name_value := String(node.name).to_lower()
		if name_value.begins_with("goalaction") and name_value.contains(period):
			count += 1
	return count

func _frames(count: int) -> void:
	for _i in range(count): await process_frame

func _check(ok: bool, reason: String) -> bool:
	if ok:return true
	push_error(reason)
	quit(1)
	return false
