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
