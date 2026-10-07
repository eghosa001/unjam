extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _run() -> void:
	var failures: Array[String] = []
	var competition = root.get_node("CompetitionManager")

	if not competition.has_method("refresh_social"):
		failures.append("CompetitionManager is missing refresh_social")
	if not competition.has_method("add_friend") or not competition.has_method("remove_friend") or not competition.has_method("rotate_friend_code"):
		failures.append("CompetitionManager is missing friend actions/privacy rotation")
	if competition.max_friends() != 50:
		failures.append("Friend cap must remain 50")

	var invalid_result: Array = []
	var invalid_callback := func(ok: bool, message: String) -> void:
		invalid_result = [ok, message]
	competition.social_action_finished.connect(invalid_callback, CONNECT_ONE_SHOT)
	competition.add_friend("BAD")
	await process_frame
	if invalid_result.is_empty() or bool(invalid_result[0]):
		failures.append("Invalid friend codes must fail locally before networking")

	var manager := _read("res://scripts/systems/competition_manager.gd")
	var ui := _read("res://scripts/ui/premium_main_casual.gd")
	var edge := _read("res://supabase/functions/unjam-competition/index.ts")
	var migration := _read("res://supabase/migrations/20261007_create_social_friends.sql")

	for token in ["social_snapshot", "friends_weekly", "MAX_FRIENDS", "add_friend", "remove_friend", "rotate_friend_code"]:
		if not manager.contains(token) and not edge.contains(token):
			failures.append("Social contract missing token: %s" % token)
	for token in ["func build_friends", "ProfileFriendsButton", "CompetitionFriendsButton", "FriendsCodeInput", "Friends Weekly", "FriendsRotateCode"]:
		if not ui.to_lower().contains(token.to_lower()):
			failures.append("Friends UI is not directly accessible: %s" % token)
	for token in ["enable row level security", "revoke all on table public.social_profiles from anon, authenticated", "revoke all on table public.social_friends from anon, authenticated", "grant select, insert, update, delete on table public.social_profiles to service_role"]:
		if not migration.to_lower().contains(token.to_lower()):
			failures.append("Social table security contract missing: %s" % token)
	if edge.contains("chat") or edge.contains("phone_number") or edge.contains("contacts"):
		failures.append("Friends backend must not introduce chat/contact-book personal data")
	if not edge.contains("const MAX_FRIENDS = 50"):
		failures.append("Server friend cap must remain 50")
	if not edge.contains("You cannot add your own code"):
		failures.append("Server must reject self-adds")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("FRIENDS_SOCIAL_OK")
	quit(0)
