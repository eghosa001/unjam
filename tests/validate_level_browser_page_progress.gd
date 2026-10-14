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
	if bar == null or count == null or panel == null:
		return false
	if bar.max_value != total or int(bar.value) != cleared:
		return false
	if count.text != "%d / %d CLEARED" % [cleared,total]:
		return false
	if not bar.accessibility_name.contains("%d of %d" % [cleared,total]):
		return false
	if bar.show_percentage or bar.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		return false
	var last := app.find_child("Level/%d" % bounds.y,true,false) as Control
	if last == null or panel.position.y < last.position.y+last.size.y+8.0:
		return false
	if panel.position.y+panel.size.y > 844.0:
		return false
	return true

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
