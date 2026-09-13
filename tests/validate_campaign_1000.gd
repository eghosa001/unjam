extends SceneTree
const MAX_LEVEL := 10000
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
 var errors: Array[String] = []
 var multi = root.get_node("MultiGameManager")
 var levels = root.get_node("LevelManager")
 var water = (load("res://scenes/WaterSort.tscn") as PackedScene).instantiate(); root.add_child(water); await process_frame
 for n in range(1, MAX_LEVEL + 1):
  water.level_number=n; var cfg:Dictionary=water.level_config(); var colors:=int(cfg.get("colors",0)); var tubes:Array=water.generate_tubes(n,colors); var counts:={}
  if tubes.size()!=colors+2: errors.append("Water %d tube count"%n)
  for tube in tubes:
   if tube.size()>4: errors.append("Water %d capacity"%n)
   for color in tube: counts[color]=int(counts.get(color,0))+1
  for color in range(colors):
   if int(counts.get(color,0))!=4: errors.append("Water %d distribution"%n)
 water.queue_free(); await process_frame
 var block=(load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate(); root.add_child(block); await process_frame
 for n in range(1,MAX_LEVEL+1):
  block.level_number=n; var cfg:Dictionary=block.level_config()
  if int(cfg.get("target_score",0))<=0 or int(cfg.get("target_lines",0))<=0 or int(cfg.get("par",0))<=0: errors.append("Block %d invalid goal"%n)
  if multi.difficulty_for_level(n) not in ["easy","medium","hard","milestone","boss"]: errors.append("Level %d invalid difficulty"%n)
 block.queue_free(); await process_frame
 for n in range(1,MAX_LEVEL+1):
  if not levels.has_level(n): errors.append("Rescue %d missing"%n)
 if multi.world_for_level(10000)!=100: errors.append("Level 10000 world mismatch")
 if not errors.is_empty():
  for e in errors.slice(0,50): push_error(e)
  push_error("30,000-level validation failed: %d errors"%errors.size()); quit(1); return
 print("All 10,000 levels validated for each game: 30,000 campaign configurations."); quit(0)
