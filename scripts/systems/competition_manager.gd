extends Node

signal snapshot_updated(snapshot: Dictionary)
signal daily_snapshot_updated(snapshot: Dictionary)
signal submission_finished(game_id: String, ok: bool, points: int)
signal weekly_reward_claimed(coins: int, crowns: int)
signal social_updated(snapshot: Dictionary)
signal social_action_finished(ok: bool, message: String)

const FUNCTION_NAME := "unjam-competition"
const GAME_IDS := ["rescue_rush", "water_sort", "block_puzzle"]
const REQUEST_TIMEOUT_SECONDS := 12.0
const DAILY_PENDING_KEY := "competition_pending_daily_results"
const MAX_PENDING_DAILY_RESULTS := 9

var snapshot: Dictionary = {}
var daily_snapshot: Dictionary = {}
var social_snapshot: Dictionary = {}
var _snapshot_in_flight := false
var _daily_snapshot_in_flight := false
var _pending_daily_requests: Dictionary = {}
var _social_in_flight := false
var _social_game_id := "rescue_rush"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("refresh_snapshot")
	call_deferred("_flush_pending_daily_results")

func display_name() -> String:
	var custom := String(SaveManager.data.get("competition_display_name", "")).strip_edges()
	if not custom.is_empty():
		return custom.left(20)
	var cloud_id := String(SaveManager.data.get("cloud_save_id", ""))
	var suffix := cloud_id.right(6).to_upper() if cloud_id.length() >= 6 else "PLAYER"
	return "PLAYER %s" % suffix

func set_display_name(value: String) -> void:
	var clean := value.strip_edges().replace("\n", " ").replace("\r", " ")
	if clean.length() > 20:
		clean = clean.left(20)
	SaveManager.data["competition_display_name"] = clean
	SaveManager.save()
	refresh_snapshot()

func _local_progress(game_id: String) -> Dictionary:
	if game_id not in GAME_IDS:
		return {}
	var highest_unlocked := clampi(int(MultiGameManager.highest_level(game_id)), 1, MultiGameManager.CAMPAIGN_LEVELS + 1)
	var levels_completed := clampi(highest_unlocked - 1, 0, MultiGameManager.CAMPAIGN_LEVELS)
	return {
		"levels_completed": levels_completed,
		"highest_level": levels_completed,
		"stars": clampi(int(MultiGameManager.total_stars(game_id)), 0, levels_completed * 3),
	}

func _all_local_progress() -> Dictionary:
	var result := {}
	for game_id in GAME_IDS:
		result[game_id] = _local_progress(game_id)
	return result

func _game_snapshot(game_id: String) -> Dictionary:
	var all_games = snapshot.get("game_rankings", {})
	if not all_games is Dictionary:
		return {}
	var value = (all_games as Dictionary).get(game_id, {})
	return value if value is Dictionary else {}

func _game_player(game_id: String, key: String) -> Dictionary:
	var value = _game_snapshot(game_id).get(key, {})
	return value if value is Dictionary else {}

func game_all_time_top(game_id: String) -> Array:
	var value = _game_snapshot(game_id).get("all_time_top", [])
	return value if value is Array else []

func game_weekly_top(game_id: String) -> Array:
	var value = _game_snapshot(game_id).get("weekly_top", [])
	return value if value is Array else []

func game_all_time_rank(game_id: String) -> int:
	return int(_game_player(game_id, "player_all_time").get("rank", 0))

func game_weekly_rank(game_id: String) -> int:
	return int(_game_player(game_id, "player_weekly").get("rank", 0))

func game_all_time_levels(game_id: String) -> int:
	return int(_game_player(game_id, "player_all_time").get("levels_completed", 0))

func game_weekly_levels(game_id: String) -> int:
	return int(_game_player(game_id, "player_weekly").get("levels_completed", 0))

func game_all_time_stars(game_id: String) -> int:
	return int(_game_player(game_id, "player_all_time").get("stars", 0))

func game_weekly_stars(game_id: String) -> int:
	return int(_game_player(game_id, "player_weekly").get("stars", 0))

func daily_top() -> Array:
	var value = daily_snapshot.get("daily_top", [])
	return value if value is Array else []

func weekly_top() -> Array:
	var value = snapshot.get("weekly_top", [])
	return value if value is Array else []

func daily_rank() -> int:
	var player = daily_snapshot.get("player_daily", {})
	return int(player.get("rank", 0)) if player is Dictionary else 0

func weekly_rank() -> int:
	var player = snapshot.get("player_weekly", {})
	return int(player.get("rank", 0)) if player is Dictionary else 0

func daily_score() -> int:
	var player = daily_snapshot.get("player_daily", {})
	return int(player.get("score", 0)) if player is Dictionary else 0

func weekly_score() -> int:
	var player = snapshot.get("player_weekly", {})
	return int(player.get("score", 0)) if player is Dictionary else 0

func weekly_division() -> String:
	var points := weekly_score()
	if points >= 14000: return "CHAMPION"
	if points >= 9000: return "DIAMOND"
	if points >= 6000: return "PLATINUM"
	if points >= 3000: return "GOLD"
	if points >= 1500: return "SILVER"
	return "BRONZE"

func friend_code() -> String:
	return String(social_snapshot.get("friend_code", ""))

func friend_count() -> int:
	return maxi(0, int(social_snapshot.get("friend_count", 0)))

func max_friends() -> int:
	return maxi(1, int(social_snapshot.get("max_friends", 50)))

func friends() -> Array:
	var value = social_snapshot.get("friends", [])
	return value if value is Array else []

func friends_all_time() -> Array:
	var value = social_snapshot.get("friends_all_time", [])
	return value if value is Array else []

func friends_weekly() -> Array:
	var value = social_snapshot.get("friends_weekly", [])
	return value if value is Array else []

func refresh_social(game_id: String = "") -> void:
	if not game_id.is_empty() and game_id in GAME_IDS:
		_social_game_id = game_id
	if OS.get_environment("UNJAM_FAST_VISUAL_AUDIT") == "1" or _social_in_flight:
		return
	var cloud_id := String(SaveManager.data.get("cloud_save_id", ""))
	if cloud_id.length() != 64:
		social_action_finished.emit(false, "Cloud identity is not ready yet")
		return
	_social_in_flight = true
	_request_json({
		"action": "social_snapshot",
		"cloud_save_id": cloud_id,
		"display_name": display_name(),
		"competition_day": DailyChallenge.date_key(),
		"game_id": _social_game_id,
	}, func(ok: bool, _status: int, body: Dictionary) -> void:
		_social_in_flight = false
		if ok and bool(body.get("ok", false)):
			social_snapshot = body.duplicate(true)
			social_updated.emit(social_snapshot)
		else:
			social_action_finished.emit(false, String(body.get("reason", "Friends service unavailable")))
	)

func add_friend(code: String) -> void:
	_social_action("add_friend", code)

func remove_friend(code: String) -> void:
	_social_action("remove_friend", code)

func rotate_friend_code() -> void:
	_social_action("rotate_friend_code", "")

func _social_action(action: String, code: String) -> void:
	var clean := code.strip_edges().to_upper().replace(" ", "").replace("-", "")
	if action != "rotate_friend_code" and clean.length() != 8:
		social_action_finished.emit(false, "Enter the 8-character friend code")
		return
	if _social_in_flight:
		social_action_finished.emit(false, "Friends are syncing. Try again.")
		return
	var cloud_id := String(SaveManager.data.get("cloud_save_id", ""))
	if cloud_id.length() != 64:
		social_action_finished.emit(false, "Cloud identity is not ready yet")
		return
	_social_in_flight = true
	var payload := {
		"action": action,
		"cloud_save_id": cloud_id,
		"display_name": display_name(),
		"competition_day": DailyChallenge.date_key(),
		"game_id": _social_game_id,
	}
	if not clean.is_empty():
		payload["friend_code"] = clean
	_request_json(payload, func(ok: bool, _status: int, body: Dictionary) -> void:
		_social_in_flight = false
		var accepted := ok and bool(body.get("ok", false))
		if accepted:
			social_snapshot = body.duplicate(true)
			social_updated.emit(social_snapshot)
			var success_message := "Friend added"
			if action == "remove_friend":
				success_message = "Friend removed"
			elif action == "rotate_friend_code":
				success_message = "New friend code created"
			social_action_finished.emit(true, success_message)
		else:
			social_action_finished.emit(false, String(body.get("reason", "Friends service unavailable")))
	)

func previous_week_reward(game_id: String = "rescue_rush") -> Dictionary:
	var value = _game_snapshot(game_id).get("previous_week_reward", {})
	return value if value is Dictionary else {}

func can_claim_weekly_reward(game_id: String = "rescue_rush") -> bool:
	var reward := previous_week_reward(game_id)
	return bool(reward.get("eligible", false)) and not bool(reward.get("claimed", false))

func refresh_snapshot() -> void:
	# Deterministic screenshot/visual-audit runs should never leave live HTTP
	# requests behind at process shutdown.
	if OS.get_environment("UNJAM_FAST_VISUAL_AUDIT") == "1":
		return
	if _snapshot_in_flight:
		return
	var cloud_id := String(SaveManager.data.get("cloud_save_id", ""))
	if cloud_id.length() != 64:
		return
	_flush_pending_daily_results()
	_snapshot_in_flight = true
	_request_json({
		"action": "progress_snapshot",
		"cloud_save_id": cloud_id,
		"display_name": display_name(),
		"competition_day": DailyChallenge.date_key(),
		"progress": _all_local_progress(),
	}, func(ok: bool, _status: int, body: Dictionary) -> void:
		_snapshot_in_flight = false
		if ok and bool(body.get("ok", false)):
			snapshot = body.duplicate(true)
			snapshot_updated.emit(snapshot)
	)

func refresh_daily_snapshot() -> void:
	# A returning offline player must not lose yesterday's submitted result.
	_flush_pending_daily_results()
	# Daily challenge rankings are a separate server view from campaign progress.
	# Never replace the campaign snapshot with daily score responses.
	if OS.get_environment("UNJAM_FAST_VISUAL_AUDIT") == "1" or _daily_snapshot_in_flight:
		return
	var cloud_id := String(SaveManager.data.get("cloud_save_id", ""))
	if cloud_id.length() != 64:
		daily_snapshot_updated.emit({})
		return
	_daily_snapshot_in_flight = true
	_request_json({
		"action": "snapshot",
		"cloud_save_id": cloud_id,
		"display_name": display_name(),
		"competition_day": DailyChallenge.date_key(),
	}, func(ok: bool, _status: int, body: Dictionary) -> void:
		_daily_snapshot_in_flight = false
		if ok and bool(body.get("ok", false)):
			daily_snapshot = body.duplicate(true)
			daily_snapshot_updated.emit(daily_snapshot)
		else:
			# Empty payload explicitly signals network failure to the UI.
			daily_snapshot_updated.emit({})
	)


func submit_campaign_progress(game_id: String, level_number: int, stars: int, first_clear: bool) -> void:
	if game_id not in GAME_IDS:
		return
	var cloud_id := String(SaveManager.data.get("cloud_save_id", ""))
	if cloud_id.length() != 64:
		submission_finished.emit(game_id, false, 0)
		return
	var local_progress := _local_progress(game_id)
	_request_json({
		"action": "submit_progress",
		"cloud_save_id": cloud_id,
		"display_name": display_name(),
		"competition_day": DailyChallenge.date_key(),
		"game_id": game_id,
		"level_number": clampi(level_number, 1, MultiGameManager.CAMPAIGN_LEVELS),
		"stars": clampi(stars, 1, 3),
		"first_clear": first_clear,
		"progress": local_progress,
		"all_progress": _all_local_progress(),
	}, func(ok: bool, _status: int, body: Dictionary) -> void:
		var accepted := ok and bool(body.get("ok", false))
		if accepted and body.get("snapshot", {}) is Dictionary:
			snapshot = (body.get("snapshot", {}) as Dictionary).duplicate(true)
			snapshot_updated.emit(snapshot)
		submission_finished.emit(game_id, accepted, int(local_progress.get("levels_completed", 0)))
	)

func submit_daily_result(game_id: String, metrics: Dictionary) -> void:
	if game_id not in GAME_IDS:
		return
	# Daily attempts are one-shot. Store the result before HTTP so temporary
	# network loss, app suspension or force-close cannot silently erase a score.
	# The server still validates the calendar day and deduplicates by player/game.
	var key := "%s:%s" % [DailyChallenge.date_key(),game_id]
	var pending := _pending_daily_results()
	pending[key] = {
		"day": DailyChallenge.date_key(),
		"game_id": game_id,
		"metrics": metrics.duplicate(true)
	}
	# Keep the queue bounded, even if a device is used without connectivity.
	var keys: Array = pending.keys()
	keys.sort()
	while keys.size() > MAX_PENDING_DAILY_RESULTS:
		pending.erase(keys.pop_front())
	SaveManager.data[DAILY_PENDING_KEY] = pending
	SaveManager.save()
	_flush_pending_daily_results()

func _pending_daily_results() -> Dictionary:
	var raw = SaveManager.data.get(DAILY_PENDING_KEY,{})
	return raw.duplicate(true) if raw is Dictionary else {}

func _flush_pending_daily_results() -> void:
	if OS.get_environment("UNJAM_FAST_VISUAL_AUDIT") == "1":
		return
	var cloud_id := String(SaveManager.data.get("cloud_save_id", ""))
	if cloud_id.length() != 64:
		return
	var pending := _pending_daily_results()
	for key_value in pending.keys():
		var key := String(key_value)
		if _pending_daily_requests.has(key):
			continue
		var row = pending[key]
		if not row is Dictionary:
			continue
		var day := String(row.get("day",""))
		var game_id := String(row.get("game_id",""))
		var metrics = row.get("metrics",{})
		if game_id not in GAME_IDS or not metrics is Dictionary:
			continue
		# The server accepts only today's and adjacent UTC day, so do not
		# repeatedly submit stale results after its 24-hour acceptance window.
		var now_unix := Time.get_unix_time_from_datetime_string("%sT12:00:00" % DailyChallenge.date_key())
		var day_unix := Time.get_unix_time_from_datetime_string("%sT12:00:00" % day)
		if absf(now_unix - day_unix) > 86400.0:
			pending.erase(key)
			SaveManager.data[DAILY_PENDING_KEY] = pending
			SaveManager.save()
			continue
		_pending_daily_requests[key] = true
		_request_json({
			"action": "submit",
			"cloud_save_id": cloud_id,
			"display_name": display_name(),
			"competition_day": day,
			"game_id": game_id,
			"metrics": (metrics as Dictionary).duplicate(true),
		}, func(ok: bool, _status: int, body: Dictionary) -> void:
			_pending_daily_requests.erase(key)
			var accepted := ok and bool(body.get("ok",false))
			var points := int(body.get("score",0)) if accepted else 0
			if accepted:
				var latest := _pending_daily_results()
				# Do not erase a newer result installed while this one was in flight.
				if latest.has(key) and latest[key] == row:
					latest.erase(key)
					SaveManager.data[DAILY_PENDING_KEY] = latest
					SaveManager.save()
				if body.get("snapshot",{}) is Dictionary:
					# A late response for yesterday must not replace today's list.
					if day == DailyChallenge.date_key():
						daily_snapshot = (body.get("snapshot",{}) as Dictionary).duplicate(true)
						daily_snapshot_updated.emit(daily_snapshot)
			submission_finished.emit(game_id, accepted, points)
		)

func claim_weekly_reward(game_id: String = "rescue_rush") -> void:
	if game_id not in GAME_IDS:
		return
	var cloud_id := String(SaveManager.data.get("cloud_save_id", ""))
	if cloud_id.length() != 64:
		return
	_request_json({
		"action": "claim_progress_weekly",
		"cloud_save_id": cloud_id,
		"display_name": display_name(),
		"competition_day": DailyChallenge.date_key(),
		"game_id": game_id,
	}, func(ok: bool, _status: int, body: Dictionary) -> void:
		if not ok or not bool(body.get("ok", false)):
			return
		var period_key := String(body.get("period_key", ""))
		var claim_key := "%s:%s" % [period_key, game_id]
		var already_claimed := bool(body.get("already_claimed", false))
		var local_claims = SaveManager.data.get("competition_claimed_periods", [])
		if not local_claims is Array:
			local_claims = []
		if already_claimed:
			if not claim_key.is_empty() and claim_key not in local_claims:
				local_claims.append(claim_key)
				SaveManager.data["competition_claimed_periods"] = local_claims
				SaveManager.save()
			refresh_snapshot()
			return
		if not period_key.is_empty() and claim_key not in local_claims:
			var coins := maxi(0, int(body.get("coins", 0)))
			var base_crowns := maxi(0, int(body.get("crowns", 0)))
			var crowns := EconomyManager.competition_crown_reward(base_crowns)
			if coins > 0:
				EconomyManager.grant(coins, "weekly_progression_reward", {
					"period": period_key,
					"game": game_id,
					"rank": int(body.get("rank", 0)),
				})
			if crowns > 0:
				SaveManager.data["crown_tokens"] = maxi(0, int(SaveManager.data.get("crown_tokens", 0))) + crowns
			local_claims.append(claim_key)
			if local_claims.size() > 312:
				local_claims = local_claims.slice(local_claims.size() - 312)
			SaveManager.data["competition_claimed_periods"] = local_claims
			SaveManager.save()
			weekly_reward_claimed.emit(coins, crowns)
		refresh_snapshot()
	)

func _request_json(payload: Dictionary, callback: Callable) -> void:
	var endpoint := _function_endpoint()
	var headers := _request_headers()
	if endpoint.is_empty() or headers.is_empty():
		if callback.is_valid():
			callback.call(false, 0, {})
		return
	var request := HTTPRequest.new()
	request.timeout = REQUEST_TIMEOUT_SECONDS
	request.max_redirects = 0
	add_child(request)
	request.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		var parsed := _decode_response_json(body)
		var success := result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300
		if callback.is_valid():
			callback.call(success, response_code, parsed)
		request.queue_free()
	)
	var error := request.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		request.queue_free()
		if callback.is_valid():
			callback.call(false, 0, {})

func _decode_response_json(body: PackedByteArray) -> Dictionary:
	if body.is_empty():
		return {}
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	return parsed if parsed is Dictionary else {}

func _function_endpoint() -> String:
	var base := String(ProjectSettings.get_setting("monetization/supabase_url", "")).strip_edges().trim_suffix("/")
	if not base.begins_with("https://"):
		return ""
	return "%s/functions/v1/%s" % [base, FUNCTION_NAME]

func _request_headers() -> PackedStringArray:
	var key := String(ProjectSettings.get_setting("monetization/supabase_publishable_key", "")).strip_edges()
	if key.is_empty():
		return PackedStringArray()
	return PackedStringArray(["Content-Type: application/json", "apikey: %s" % key])
