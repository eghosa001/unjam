extends SceneTree

# Empirical first-200 difficulty survey on real deterministic campaign boards.
# Scores alone cannot demonstrate playability. Collect solution length, hard
# structural lower bounds, branch pressure and bot success where available.
const Rescue = preload("res://scripts/core/campaign_generator.gd")
const RescueSolver = preload("res://scripts/core/puzzle_solver.gd")
const WaterProgression = preload("res://scripts/core/water_sort_progression.gd")
const BlockProgression = preload("res://scripts/core/block_puzzle_progression.gd")
const BlockPack = preload("res://scripts/core/block_puzzle_level_pack.gd")
const BlockGenerator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")
const BlockAuditor = preload("res://scripts/core/block_puzzle_campaign_auditor.gd")

const BANDS: Array[Vector2i] = [
	Vector2i(1,3),Vector2i(4,10),Vector2i(11,25),
	Vector2i(26,50),Vector2i(51,100),Vector2i(101,150),
	Vector2i(151,200)
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var which := OS.get_environment("OPENING_200_GAME")
	match which:
		"rescue":
			if not _rescue(): return
		"water":
			if not await _water(): return
		"block":
			if not _block(): return
		_:
			return _fail("Missing OPENING_200_GAME matrix value")
	print("OPENING_200_SURVEY_OK game=%s" % which)
	quit(0)

func _rescue() -> bool:
	var bins: Dictionary = {}
	var weak: Array[int] = []
	var too_open: Array[int] = []
	var duplicate_signatures: Array[int] = []
	var seen := {}
	for level in range(1,201):
		var board: Dictionary = Rescue.generate(level)
		if board.is_empty() or not bool(board.get("solver_verified",false)):
			return _fail("Rescue %d did not yield a verified board" % level)
		var proof: Array[int] = RescueSolver.find_solution(board, [], 6000)
		if proof.is_empty():
			return _fail("Rescue %d has no executable solution" % level)
		var depth := int(board.get("dependency_depth",0))
		var frontier := int(board.get("initial_frontier",0))
		var decoys := int(board.get("false_clear_candidates",0))
		var piece_count := int(board.get("actual_piece_count",0))
		var band := _band_for(level)
		var b: Dictionary = bins.get(band,_new_bin())
		_bump(b, proof.size())
		b["dependency_sum"] = int(b.get("dependency_sum",0)) + depth
		b["frontier_sum"] = int(b.get("frontier_sum",0)) + frontier
		b["piece_sum"] = int(b.get("piece_sum",0)) + piece_count
		b["decoy_sum"] = int(b.get("decoy_sum",0)) + decoys
		bins[band] = b
		if level >= 25 and proof.size() <= 6:
			weak.append(level)
		if level >= 25 and depth < 3:
			too_open.append(level)
		var sig := String(board.get("structural_signature",""))
		if sig.is_empty(): return _fail("Rescue missing structural signature at %d" % level)
		if seen.has(sig): duplicate_signatures.append(level)
		seen[sig]=level
		if level in [1,3,5,10,25,50,75,100,101,125,150,175,199,200] or (level>=25 and proof.size()<=6):
			print("OPENING_RESCUE level=%d proof=%d deps=%d frontier=%d decoys=%d pieces=%d role=%s" % [
				level,proof.size(),depth,frontier,decoys,piece_count,String(board.get("level_role",""))])
	for key in bins:
		print("OPENING_RESCUE_BAND %s %s" % [String(key),str(bins[key])])
	print("OPENING_RESCUE_FINDINGS levels_25plus_solution_6or_less=%s levels_25plus_dependencies_below3=%s structural_duplicates=%s" % [
		str(weak),str(too_open),str(duplicate_signatures)])
	return true

func _water() -> bool:
	var scene := load("res://scenes/WaterSort.tscn") as PackedScene
	if scene == null: return _fail("Cannot load Water Sort playable scene")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	var bins: Dictionary = {}
	var weak: Array[int] = []
	var nearly_sorted: Array[int] = []
	var seen := {}
	var dupes: Array[int] = []
	for level in range(1,201):
		var profile: Dictionary = WaterProgression.profile(level)
		game.level_number = level
		var board: Dictionary = game.call("generate_tubes_with_solution", level, int(profile.get("colors",4)))
		var proof: Array = board.get("solution",[])
		var tubes: Array = board.get("tubes",[])
		if proof.is_empty() or tubes.is_empty():
			return _fail("Water %d has empty actual board / proof" % level)
		var metrics: Dictionary = WaterProgression.score_board(tubes,proof.size())
		var lower := int(metrics.get("unavoidable_pours_lower_bound",0))
		var solved_tubes := 0
		for raw in tubes:
			var tube: Array = raw
			if tube.size()==4 and tube[0]==tube[1] and tube[1]==tube[2] and tube[2]==tube[3]:
				solved_tubes += 1
		var band := _band_for(level)
		var b: Dictionary = bins.get(band,_new_bin())
		_bump(b,proof.size())
		b["lower_sum"] = int(b.get("lower_sum",0)) + lower
		b["lower_min"] = mini(int(b.get("lower_min",100000)), lower)
		b["solved_tubes_sum"] = int(b.get("solved_tubes_sum",0)) + solved_tubes
		bins[band]=b
		var minimum := WaterProgression.minimum_required_pours(level,int(profile.get("empty_bottles",2)))
		if level >= 11 and (lower < minimum or proof.size() < WaterProgression.minimum_proof_moves(level,int(profile.get("empty_bottles",2)))):
			weak.append(level)
		if level >= 25 and solved_tubes >= 3:
			nearly_sorted.append(level)
		var sig := String(metrics.get("canonical_signature",""))
		if seen.has(sig): dupes.append(level)
		seen[sig]=level
		if level in [1,3,4,5,6,10,25,50,75,100,101,125,150,175,199,200]:
			print("OPENING_WATER level=%d proof=%d lower=%d solved_tubes=%d colors=%d empties=%d source=%s" % [
				level,proof.size(),lower,solved_tubes,int(profile.get("colors",0)),
				int(profile.get("empty_bottles",0)),String((board.get("metadata",{}) as Dictionary).get("source","generated"))])
	for key in bins:
		print("OPENING_WATER_BAND %s %s" % [String(key),str(bins[key])])
	print("OPENING_WATER_FINDINGS under_minimum=%s nearly_sorted_after_25=%s duplicates=%s" % [str(weak),str(nearly_sorted),str(dupes)])
	game.queue_free()
	await process_frame
	return true

func _block() -> bool:
	var bins: Dictionary = {}
	var weak: Array[int] = []
	var low_diversity: Array[int] = []
	var too_open: Array[int] = []
	var failures: Array[int] = []
	var seen := {}
	var dupes: Array[int] = []
	var bot_success: Dictionary = {}
	for level in range(1,201):
		var p: Dictionary = BlockProgression.profile(level)
		if level <= 10:
			p["target_score"] = [100,130,165,190,220,255,285,315,350,390][level-1]
			p["target_lines"] = [2,2,3,3,3,4,4,4,5,5][level-1]
		var plan: Dictionary = BlockPack.plan_for_level(level,p)
		if plan.is_empty():
			failures.append(level)
			continue
		var replay: Dictionary = BlockGenerator.replay_proof(plan,int(p.get("target_lines",2)),int(p.get("target_score",100)))
		if not bool(replay.get("solved",false)):
			failures.append(level)
			continue
		var proof := int(replay.get("moves",0))
		var q: Dictionary = BlockAuditor.quality_gate(p,plan)
		var unique := int(q.get("unique_shapes",0))
		var occupied := int(q.get("initial_occupied",0))
		var avg_choices := float(q.get("average_legal_choices",0.0))
		var band := _band_for(level)
		var b: Dictionary = bins.get(band,_new_bin())
		_bump(b,proof)
		b["shapes_sum"] = int(b.get("shapes_sum",0)) + unique
		b["occupied_sum"] = int(b.get("occupied_sum",0)) + occupied
		b["choices_sum"] = float(b.get("choices_sum",0.0)) + avg_choices
		bins[band]=b
		if level >= 25 and proof <= 6: weak.append(level)
		if level >= 25 and unique < 3: low_diversity.append(level)
		if level >= 50 and occupied < 10: too_open.append(level)
		var signature := BlockAuditor.canonical_signature(p,plan)
		if seen.has(signature): dupes.append(level)
		seen[signature]=level
		if level in [1,3,5,10,25,50,75,100,101,125,150,175,199,200]:
			print("OPENING_BLOCK level=%d proof=%d occupied=%d shapes=%d choices=%.2f role=%s quality=%s" % [
				level,proof,occupied,unique,avg_choices,String(p.get("retention_role","")),str(q.get("reasons",[]))])
		if level in [5,10,25,50,100,150,200]:
			var report: Dictionary = BlockAuditor.audit_plan(p,plan)
			bot_success[level] = float(report.get("bot_success_rate",-1.0))
	for key in bins:
		print("OPENING_BLOCK_BAND %s %s" % [String(key),str(bins[key])])
	print("OPENING_BLOCK_FINDINGS failures=%s proof_6or_less_after25=%s fewer_than_3_shapes_after25=%s low_occupancy_50plus=%s duplicates=%s bot_success=%s" % [
		str(failures),str(weak),str(low_diversity),str(too_open),str(dupes),str(bot_success)])
	if not failures.is_empty(): return _fail("Block levels invalid %s" % str(failures))
	return true

func _band_for(level: int) -> String:
	for band in BANDS:
		if level >= band.x and level <= band.y:
			return "%d-%d" % [band.x,band.y]
	return "unknown"

func _new_bin() -> Dictionary:
	return {"count":0,"proof_min":100000,"proof_max":0,"proof_sum":0,"proof_6_or_less":0,"proof_10_or_less":0,"lower_min":100000}

func _bump(bin: Dictionary, proof: int) -> void:
	bin["count"] = int(bin.get("count",0))+1
	bin["proof_min"] = mini(int(bin.get("proof_min",100000)),proof)
	bin["proof_max"] = maxi(int(bin.get("proof_max",0)),proof)
	bin["proof_sum"] = int(bin.get("proof_sum",0))+proof
	if proof <= 6: bin["proof_6_or_less"] = int(bin.get("proof_6_or_less",0))+1
	if proof <= 10: bin["proof_10_or_less"] = int(bin.get("proof_10_or_less",0))+1

func _fail(message: String) -> bool:
	push_error("OPENING_200_FAILED: "+message)
	quit(1)
	return false
