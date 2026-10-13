extends SceneTree

func _initialize() -> void:
  call_deferred("_run")

func _run() -> void:
  var edge := FileAccess.get_file_as_string("res://supabase/functions/unjam-competition/index.ts")
  var water := FileAccess.get_file_as_string("res://scripts/game/water_sort_10000.gd")
  var block := FileAccess.get_file_as_string("res://scripts/game/block_puzzle.gd")
  var rescue := FileAccess.get_file_as_string("res://scripts/game/game.gd")
  if not _check(edge.contains("validDailyMetrics(gameId, metrics)") and edge.contains("Incomplete or invalid daily result"), "Daily score server still accepts empty stats"):return
  if not _check(water.contains("CompetitionManager.submit_daily_result(GAME_ID") and water.contains('"par": maxi(1, par_moves)'), "Water Sort daily wins do not reach online rankings"):return
  if not _check(block.contains("CompetitionManager.submit_daily_result(GAME_ID") and block.contains('"placements":maxi(1,placements)'), "Block Puzzle daily score missing required metrics"):return
  if not _check(rescue.contains('CompetitionManager.submit_daily_result("rescue_rush"') and rescue.contains('"undos": maxi(0,undos_used_this_level)'), "Rescue daily score missing required metrics"):return
  for key in ['integer("stars", 1, 3)', 'integer("moves", 1, 500)', 'integer("par", 1, 500)',
              'integer("moves", 1, 1000)', 'integer("placements", 1, 1000)', 'integer("score", 0, 100000)']:
    if not _check(edge.contains(key), "Daily stat validation missing bound: %s" % key):return
  print("DAILY_SCORE_CONTRACT_OK: all three puzzles submit complete bounded stats, empty scores rejected")
  quit(0)

func _check(value: bool, message: String) -> bool:
  if value: return true
  push_error(message)
  quit(1)
  return false
