extends SceneTree

# Keeps the premium clear spectacle without three overlapping sounds / haptics.
# Active class order: BlockPuzzle10000 -> FinalPolish -> 3D -> UltraMotion.
func _initialize() -> void:
	var errors: Array[String] = []
	var base := _method("res://scripts/game/block_puzzle_3d.gd", "_spawn_clear_feedback")
	var ultra := _method("res://scripts/game/block_puzzle_ultra_motion.gd", "_spawn_clear_feedback")
	var final := _method("res://scripts/game/block_puzzle_final_polish.gd", "_spawn_clear_feedback")
	var active := _method("res://scripts/game/block_puzzle_10000.gd", "_spawn_clear_feedback")
	if base.is_empty() or ultra.is_empty() or final.is_empty() or active.is_empty():
		errors.append("Block clear feedback inheritance chain incomplete")
	if base.count("FeedbackManager.line_clear(") != 1 or base.count("FeedbackManager.combo(") != 1:
		errors.append("Exactly one basic and multi-line sound beat must live in the board owner")
	if base.count("MotionSystem.local_punch(") != 1:
		errors.append("Exactly one basic board punch must live in the board owner")
	if ultra.contains("FeedbackManager.line_clear(") or ultra.contains("FeedbackManager.combo(") or ultra.contains("MotionSystem.local_punch("):
		errors.append("Ultra Motion still replays inherited sounds and competing tweens")
	if active.contains("FeedbackManager.line_clear(") or active.contains("FeedbackManager.combo(") or active.contains("MotionSystem.local_punch("):
		errors.append("Active 10k-level premium sweep duplicates sound/board impact")
	if not final.contains("if line_count < 2:") or final.count("FeedbackManager.combo(") != 1:
		errors.append("Consecutive single-line clear streak needs its own distinct combo cue")
	if not errors.is_empty():
		for reason in errors:
			push_error(reason)
		quit(1)
		return
	print("BLOCK_CLEAR_SOUND_OWNER_OK: one base line-clear, one multi-line combo and one local board punch")
	quit(0)

func _method(path: String, method: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return ""
	var source := file.get_as_text()
	var begin := source.find("func %s(" % method)
	if begin < 0: return ""
	var end := source.find("\nfunc ", begin + 1)
	return source.substr(begin, end - begin if end >= 0 else source.length() - begin)
