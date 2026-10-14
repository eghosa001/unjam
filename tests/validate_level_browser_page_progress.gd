extends SceneTree

# One focused runtime check: level-browser completion rail is truthful and
# stays below the 20 game tiles on compact mobile layouts.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if main_scene == null:
		return _fail("Main scene unavailable")
	var app := main_scene.instantiate() as Control
	root.add_child(app)
	for _i in range(6): await process_frame
	app.call("build_level_select")
	for _i in range(3): await process_frame
	if not _check_page(app,"rescue_rush"):
		return _fail("Rescue progress rail is missing or inaccurate")
	app.call("_figma_switch_level_game","block_puzzle")
	for _i in range(3): await process_frame
	if not _check_page(app,"block_puzzle"):
		return _fail("Block page progress does not fit below its mode selector")
	app.queue_free()
	await process_frame
	print("LEVEL_BROWSER_PAGE_PROGRESS_OK")
	quit(0)

func _check_page(app: Control, game_id: String) -> bool:
	var bar := app.find_child("LevelPageProgressBar",true,false) as ProgressBar
	var count := app.find_child("LevelPageProgressCount",true,false) as Label
	var instruction := app.find_child("LevelUnlockGuidance",true,false) as Label
	var panel := app.find_child("LevelPageProgressCard",true,false) as Control
	var world := int(app.get("selected_multi_world"))
	var page := int(app.get("selected_multi_page"))
	var bounds: Vector2i = app.call("_multi_page_bounds",game_id,world,page)
	var cleared := 0
	var games := root.get_node_or_null("MultiGameManager")
	if games == null:
		return false
	for level_number in range(bounds.x,bounds.y+1):
		if int(games.call("get_stars",game_id,level_number)) > 0:
			cleared += 1
	var total := maxi(1,bounds.y-bounds.x+1)
	if bar == null or count == null or panel == null or instruction == null:
		return false
	var current_level := int(app.call("_highest_level_for_game",game_id))
	if cleared < total and current_level >= bounds.x and current_level < bounds.y:
		var expected_guidance := "BEAT LEVEL %d TO UNLOCK %d" % [current_level,current_level+1]
		if instruction.text != expected_guidance:
			print("Unexpected unlock guidance: ",instruction.text," vs ",expected_guidance)
			return false
	if instruction.text.strip_edges().is_empty() or instruction.get_theme_font_size("font_size") < 12:
		return false
	var locked_number := -1
	for level_number in range(bounds.x,bounds.y+1):
		if not bool(games.call("is_level_unlocked",game_id,level_number)):
			locked_number = level_number
			break
	if locked_number >= 0:
		var lock_label := app.find_child("LevelStatus_%d" % locked_number,true,false) as Label
		var number := app.find_child("LevelNumber_%d" % locked_number,true,false) as Label
		if lock_label == null or lock_label.text != "LOCKED" or lock_label.get_theme_font_size("font_size") < 12 or number == null:
			return false
		if number.get_theme_font_size("font_size") < 15:
			return false
	if bar.max_value != total or int(bar.value) != cleared:
		return false
	if count.text != "%d / %d CLEARED" % [cleared,total]:
		return false
	if not bar.accessibility_name.contains("%d of %d" % [cleared,total]):
		return false
	if bar.show_percentage or bar.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		return false
	# The numbered tile names are sanitized by Godot because '/' is not a
	# legal Node name; derive the final authored tile's end from grid geometry.
	var grid_y := 308.0 if game_id == "block_puzzle" else 269.0
	var bottom_of_tiles := grid_y+float(int((total-1)/4))*80.0+70.0
	if panel.position.y < bottom_of_tiles+8.0:
		print("Page progress overlaps the final level tile: ",panel.position.y," vs ",bottom_of_tiles)
		return false
	if panel.position.y+panel.size.y > 844.0:
		print("Page progress escaped authored screen: ",panel.position.y+panel.size.y)
		return false
	return true

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
