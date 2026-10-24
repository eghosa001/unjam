extends SceneTree

# Measures ACTUAL playable boards/proofs at world boundaries and late-game
# hotspots, not only decorative difficulty labels. Full catalogs are checked
# by the adjacent three-game audit workflow.
const RescueProgression = preload("res://scripts/core/rescue_rush_progression.gd")
const RescueGenerator = preload("res://scripts/core/campaign_generator.gd")
const WaterProgression = preload("res://scripts/core/water_sort_progression.gd")
const WaterCatalog = preload("res://scripts/core/water_sort_curated_catalog.gd")
const BlockProgression = preload("res://scripts/core/block_puzzle_progression.gd")
const BlockPack = preload("res://scripts/core/block_puzzle_level_pack.gd")
const BlockGenerator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")
const BlockAuditor = preload("res://scripts/core/block_puzzle_campaign_auditor.gd")

const SAMPLES: Array[int] = [
	1,2,3,9,10,11,25,50,75,99,100,101,249,250,251,499,500,501,
	999,1000,1001,1499,1500,1501,1999,2000,2001,2499,2500,2501,
	2999,3000,3001,3999,4000,4001,4999,5000,5001,5999,6000,6001,
	6999,7000,7001,7499,7500,7501,7999,8000,8001,8999,9000,9001,
	9499,9500,9501,9699,9700,9701,9799,9800,9801,9899,9900,9901,
	9949,9950,9951,9990,9991,9997,9998,9999,10000
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := OS.get_environment("UNJAM_CAMPAIGN_AUDIT_GAME")
	var success := false
	match game:
		"rescue": success = _check_rescue()
		"water": success = _check_water()
		"block": success = _check_block()
		_: return _fail("Unknown campaign audit game: " + game)
	if not success:
		return
	print("LATE_CAMPAIGN_PLAYABILITY_OK game=%s samples=%d" % [game, SAMPLES.size()])
	quit(0)

func _check_rescue() -> bool:
	var previous := -1
	var max_jump := 0
	var high_run := 0
	var max_high_run := 0
	var recovery_count := 0
	for n in range(1, 10001):
		var p: Dictionary = RescueProgression.profile(n)
		var target := int(p.get("difficulty_target", -1))
		if target < 10 or target > 99:
			return _fail("Rescue invalid difficulty at level %d: %d" % [n,target])
		if previous >= 0:
			max_jump = maxi(max_jump, absi(target - previous))
		previous = target
		if target >= 90:
			high_run += 1
			max_high_run = maxi(max_high_run, high_run)
		else:
			high_run = 0
		if String(p.get("level_role", "")) == "recovery":
			recovery_count += 1
	var fallbacks := 0
	var lengths: Array[int] = []
	var max_length := 0
	for n in SAMPLES:
		var board: Dictionary = RescueGenerator.generate(n)
		if board.is_empty():
			return _fail("Rescue produced an empty level %d" % n)
		if not bool(board.get("solver_verified", false)):
			return _fail("Rescue generated level %d without solver proof" % n)
		var upper := int(board.get("solution_upper_bound", board.get("optimal_moves", 0)))
		var budget := int(board.get("action_budget", -1))
		if upper <= 0:
			return _fail("Rescue level %d has no playable solution length" % n)
		if String(board.get("objective", "")) == "perfect_rescue" and budget > 0 and budget < upper:
			return _fail("Rescue perfect objective %d has %d-step solution but %d move allowance" % [n,upper,budget])
		fallbacks += 1 if int(board.get("generation_attempt", 0)) == 0 else 0
		max_length = maxi(max_length,upper)
		lengths.append(upper)
		if n >= 9000:
			print("RESCUE_ENDGAME level=%d target=%d pieces=%d proof=%d allowance=%d role=%s generated=%d" % [
				n,int(board.get("difficulty_score",0)),int(board.get("actual_piece_count",0)),
				upper,budget,String(board.get("level_role","")),int(board.get("generation_attempt",0))])
	print("RESCUE_BALANCE_REPORT scanned=10000 samples=%d biggest_adjacent_target_jump=%d longest_90_plus_streak=%d recovery_levels=%d fallback_samples=%d longest_solver_proof=%d proof_lengths=%s" % [
		SAMPLES.size(),max_jump,max_high_run,recovery_count,fallbacks,max_length,str(lengths)])
	if max_jump > 20 or max_high_run > 4:
		return _fail("Rescue authored difficulty curve has a cliff/extended high-pressure streak")
	return true

func _check_water() -> bool:
	var previous := -1
	var max_target_step := 0
	var one_empty_late := 0
	var max_one_empty_run := 0
	var one_empty_run := 0
	var recoveries_late := 0
	for n in range(1, 10001):
		var p: Dictionary = WaterProgression.profile(n)
		var moves := int(p.get("target_moves", -1))
		var colors := int(p.get("colors", 0))
		var empties := int(p.get("empty_bottles", 0))
		if moves < 1 or colors < 3 or colors > 12 or empties < 1 or empties > 2:
			return _fail("Water invalid playable profile at %d" % n)
		if previous >= 0:
			max_target_step = maxi(max_target_step, absi(moves - previous))
		previous = moves
		if n >= 9001:
			if empties == 1:
				one_empty_late += 1
				one_empty_run += 1
				max_one_empty_run = maxi(max_one_empty_run, one_empty_run)
			else:
				one_empty_run = 0
			if String(p.get("retention_role","")) == "recovery":
				recoveries_late += 1
	var max_proof := 0
	var max_lower_bound := 0
	var proof_lengths: Array[int] = []
	for n in SAMPLES:
		var authored: Dictionary = WaterCatalog.level(n)
		if authored.is_empty():
			return _fail("Water curated level %d missing" % n)
		var proof: Array = authored.get("solution", [])
		var profile: Dictionary = WaterProgression.profile(n)
		if proof.is_empty() or proof.size() > int(profile.get("three_star_limit", 0)):
			return _fail("Water curated level %d proof %d exceeds 3-star allowance %d" % [n,proof.size(),int(profile.get("three_star_limit",0))])
		var metrics: Dictionary = WaterProgression.score_board(authored.get("tubes", []), proof.size())
		var lower := int(metrics.get("unavoidable_pours_lower_bound", -1))
		if lower < 0 or lower > proof.size():
			return _fail("Water curated level %d impossible lower vs upper bound" % n)
		max_proof = maxi(max_proof,proof.size())
		max_lower_bound = maxi(max_lower_bound,lower)
		proof_lengths.append(proof.size())
		if n >= 9000:
			print("WATER_ENDGAME level=%d colors=%d empties=%d proof=%d lower=%d 3star=%d target=%d role=%s" % [
				n,int(profile.get("colors",0)),int(profile.get("empty_bottles",0)),
				proof.size(),lower,int(profile.get("three_star_limit",0)),
				int(profile.get("target_moves",0)),String(profile.get("retention_role",""))])
	print("WATER_BALANCE_REPORT scanned=10000 samples=%d biggest_adjacent_move_target_jump=%d one_empty_in_final1000=%d longest_one_empty_streak=%d late_recovery_count=%d max_proof=%d max_required_lower_bound=%d lengths=%s" % [
		SAMPLES.size(),max_target_step,one_empty_late,max_one_empty_run,recoveries_late,max_proof,max_lower_bound,str(proof_lengths)])
	WaterCatalog.clear_cache()
	return true

func _check_block() -> bool:
	var prev := -1
	var largest_score_jump := 0
	var recovery_count := 0
	var late_max_occupancy := 0.0
	for n in range(1, 10001):
		var p: Dictionary = BlockProgression.profile(n)
		var score := int(p.get("difficulty_score", -1))
		var occupancy := float(p.get("initial_occupancy",0.0))
		if score < 10 or score > 100 or occupancy < 0.0 or occupancy > 0.65:
			return _fail("Block invalid difficulty/occupancy at level %d" % n)
		if prev >= 0:
			largest_score_jump = maxi(largest_score_jump, absi(score - prev))
		prev = score
		if String(p.get("retention_role","")) == "recovery":
			recovery_count += 1
		if n >= 9000:
			late_max_occupancy = maxf(late_max_occupancy,occupancy)
	var max_proof_moves := 0
	var failing_quality := 0
	var quality_reasons := {}
	var generator_failures := 0
	var unplayable_profile_limits := 0
	var proof_counts: Array[int] = []
	for n in SAMPLES:
		var p: Dictionary = BlockProgression.profile(n)
		# This is the SAME runtime plan selection as the shipping game.
		var plan: Dictionary = BlockPack.plan_for_level(n, p)
		if plan.is_empty():
			generator_failures += 1
			print("BLOCK_FAILED_GENERATION level=%d score=%d horizon=%d role=%s" % [
				n,int(p.get("difficulty_score",0)),int(p.get("planning_horizon",0)),String(p.get("retention_role",""))])
			continue
		var replay: Dictionary = BlockGenerator.replay_proof(plan, int(p.get("target_lines",0)),int(p.get("target_score",0)))
		if not bool(replay.get("solved",false)):
			return _fail("Block playable level %d generated plan without winning solution" % n)
		var moves := int(replay.get("moves",0))
		var limit := int(p.get("move_limit",-1))
		if limit > 0 and moves > limit:
			unplayable_profile_limits += 1
			print("BLOCK_METADATA_LIMIT_BELOW_PROOF level=%d proof=%d profile_limit=%d (normal campaign runtime disables this limit)" % [n,moves,limit])
		max_proof_moves = maxi(max_proof_moves,moves)
		proof_counts.append(moves)
		var quality: Dictionary = BlockAuditor.quality_gate(p,plan)
		if not bool(quality.get("accepted",false)):
			failing_quality += 1
			for reason in (quality.get("reasons",[]) as Array):
				quality_reasons[str(reason)] = int(quality_reasons.get(str(reason),0)) + 1
		if n >= 9000:
			print("BLOCK_ENDGAME level=%d difficulty=%d proof=%d limit=%d occupancy=%d accepted=%s reasons=%s" % [
				n,int(p.get("difficulty_score",0)),moves,limit,
				int((plan.get("metadata",{}) as Dictionary).get("initial_occupancy",0)),
				str(bool(quality.get("accepted",false))),str(quality.get("reasons",[]))])
	print("BLOCK_BALANCE_REPORT scanned=10000 samples=%d precomputed_pack=%s biggest_adjacent_target_jump=%d recovery_levels=%d max_late_occupancy_fraction=%.3f generation_failures=%d profile_limits_below_proof=%d failed_quality=%d quality_reasons=%s max_proof=%d proof_counts=%s" % [
		SAMPLES.size(),str(BlockPack.has_production_pack()),largest_score_jump,recovery_count,
		late_max_occupancy,generator_failures,unplayable_profile_limits,failing_quality,
		str(quality_reasons),max_proof_moves,str(proof_counts)])
	if generator_failures > 0:
		return _fail("Block campaign runtime generator returned empty playable plans at %d sampled milestones" % generator_failures)
	return true

func _fail(message: String) -> bool:
	push_error("LATE_CAMPAIGN_AUDIT_FAILED: "+message)
	quit(1)
	return false
