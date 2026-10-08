extends RefCounted

# Predictable, offline guidance built from verified campaign progress. This
# chooses a strategy, never fabricates an exact solver move or reads user data
# beyond local progression. Tip text stays in the existing localization table.
static func recommended_tip_index(game_id: String, level: int, last_stars: int, perfect_streak: int) -> int:
	var campaign_level := clampi(level, 1, 10000)
	var previous_result := clampi(last_stars, 0, 3)
	var streak := maxi(0, perfect_streak)
	match game_id:
		"rescue_rush":
			if campaign_level <= 12:
				return 1 # Observe the exit lane first.
			if previous_result in [1, 2]:
				return 1 # A lower-rated clear merits careful route planning.
			if campaign_level % 100 >= 75:
				return 2 # Conserve paid hints in milestone stretches.
			if streak >= 3:
				return 0 # Keep building on an effective approach.
			return 0
		"water_sort":
			if campaign_level <= 20:
				return 1 # One working tube prevents early dead ends.
			if previous_result in [1, 2]:
				return 1 # Reduce unnecessary rearrangements.
			if streak >= 3 or campaign_level >= 100:
				return 2 # Spot long, matching colour runs.
			return 0
		"block_puzzle":
			if campaign_level <= 20:
				return 2 # Check all three tray pieces before committing.
			if previous_result in [1, 2]:
				return 1 # Favour early line clears when struggling.
			if streak >= 3 or campaign_level >= 100:
				return 0 # Maintain placement space for bigger shapes.
			return 1
	return 0

# Sidekick only inspects saved, *campaign* puzzle positions. It cannot see
# a currently moving/animating board and never guesses a specific winning move.
# Invalid, stale or truncated checkpoints are ignored, rather than shown as
# if they described the current level.
static func checkpoint_guidance(game_id: String, level: int, snapshot: Dictionary, fallback_tip: int) -> Dictionary:
	var result := {"active": false, "tip_index": clampi(fallback_tip, 0, 2), "status": "", "recovery_tip": ""}
	if snapshot.is_empty() or int(snapshot.get("level", -1)) != level:
		return result
	if bool(snapshot.get("daily", false)):
		return result
	var checkpoint_game := String(snapshot.get("game", game_id))
	if checkpoint_game != game_id:
		return result
	match game_id:
		"water_sort":
			var raw_tubes = snapshot.get("tubes", null)
			if not raw_tubes is Array or raw_tubes.size() < 2 or raw_tubes.size() > 20:
				return result
			var empty_tubes := 0
			var legal_pours := 0
			for tube in raw_tubes:
				if not tube is Array or tube.size() > 4:
					return result
				for color in tube:
					if not color is int and not color is float:
						return result
				if tube.is_empty():
					empty_tubes += 1
			for from_idx in range(raw_tubes.size()):
				var source: Array = raw_tubes[from_idx]
				if source.is_empty():
					continue
				for to_idx in range(raw_tubes.size()):
					if from_idx == to_idx:
						continue
					var target: Array = raw_tubes[to_idx]
					if target.size() >= 4:
						continue
					if target.is_empty() or int(source.back()) == int(target.back()):
						legal_pours += 1
			result.active = true
			result.tip_index = 1 if empty_tubes <= 1 else (2 if legal_pours >= 8 else 0)
			result.status = "%d EMPTY TUBES • %d MOVES" % [empty_tubes, maxi(0, int(snapshot.get("moves", 0)))]
			if legal_pours == 0:
				# A completed sorted board is handled by the game, not as a deadlock.
				var solved := true
				for tube in raw_tubes:
					if tube.is_empty():
						continue
					if tube.size() != 4:
						solved = false
						break
					for color in tube:
						if color != tube[0]:
							solved = false
							break
				if not solved:
					result.status = "NO LEGAL POUR • %d MOVES" % maxi(0, int(snapshot.get("moves", 0)))
					result.recovery_tip = "No legal pour remains. Undo, add a tube, or retry."
		"block_puzzle":
			var raw_cells = snapshot.get("cells", null)
			if not raw_cells is Array or raw_cells.size() != 8:
				return result
			var occupied := 0
			for row in raw_cells:
				if not row is Array or row.size() != 8:
					return result
				for cell in row:
					if not cell is bool:
						return result
					if cell:
						occupied += 1
			result.active = true
			result.tip_index = 1 if occupied >= 40 else (0 if occupied >= 24 else 2)
			result.status = "%d/64 FILLED CELLS • %d MOVES" % [occupied, maxi(0, int(snapshot.get("placements", 0)))]
			# Only issue a deadlock claim if every non-empty saved tray piece was
			# decoded successfully and checked against every legal 8×8 origin.
			var shapes = snapshot.get("pieces", null)
			if shapes is Array and not shapes.is_empty() and shapes.size() <= 3:
				var has_shape := false
				var all_decoded := true
				var has_fit := false
				for raw_shape in shapes:
					if not raw_shape is Array or raw_shape.size() > 16:
						all_decoded = false
						break
					if raw_shape.is_empty():
						continue
					has_shape = true
					var points: Array[Vector2i] = []
					for raw_point in raw_shape:
						var point := _checked_block_point(raw_point)
						if point.x < 0 or point.x >= 8 or point.y < 0 or point.y >= 8:
							all_decoded = false
							break
						points.append(point)
					if not all_decoded:
						break
					for y in range(8):
						for x in range(8):
							var fits := true
							for point in points:
								var px := x + point.x
								var py := y + point.y
								if px >= 8 or py >= 8 or bool(raw_cells[py][px]):
									fits = false
									break
							if fits:
								has_fit = true
								break
						if has_fit:
							break
					if has_fit:
						break
				if all_decoded and has_shape and not has_fit:
					result.status = "NO PIECE FITS • %d MOVES" % maxi(0, int(snapshot.get("placements", 0)))
					result.recovery_tip = "No tray piece fits. Retry and keep more space open."
		"rescue_rush":
			var raw_pieces = snapshot.get("pieces", null)
			if not raw_pieces is Array or raw_pieces.is_empty():
				return result
			for piece in raw_pieces:
				if not piece is Dictionary:
					return result
			var misses := maxi(0, int(snapshot.get("mistakes", 0)))
			result.active = true
			result.tip_index = 1 if misses > 0 else fallback_tip
			result.status = "%d MOVES • %d BLOCKED TAPS" % [maxi(0, int(snapshot.get("moves", 0))), misses]
	return result

# Match the game board's serialized point types without interpreting an
# unrecognized representation as an impossible move.
static func _checked_block_point(raw: Variant) -> Vector2i:
	if raw is Vector2i:
		return raw
	if raw is Vector2:
		return Vector2i(raw)
	if raw is Dictionary and raw.has("x") and raw.has("y"):
		return Vector2i(int(raw["x"]), int(raw["y"]))
	if raw is Array and raw.size() >= 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	if raw is String:
		var value := String(raw).replace("Vector2i", "").replace("(", "").replace(")", "")
		var parts := value.split(",")
		if parts.size() >= 2:
			var px := String(parts[0]).strip_edges()
			var py := String(parts[1]).strip_edges()
			if px.is_valid_int() and py.is_valid_int():
				return Vector2i(int(px), int(py))
	return Vector2i(-1, -1)
