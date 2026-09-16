extends SceneTree

const REQUIRED_SCRIPTS := [
	"res://scripts/ui/premium_3d_materials.gd",
	"res://scripts/ui/premium_3d_stage.gd",
	"res://scripts/ui/water_sort_3d_stage.gd",
	"res://scripts/ui/rescue_rush_3d_stage.gd",
	"res://scripts/ui/block_puzzle_3d_stage.gd",
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_scripts_exist_and_load(): return
	if not _validate_material_contract(): return
	if not _validate_stage_contract(): return
	if not _validate_game_stage_contracts(): return
	if not _validate_active_game_wiring(): return
	print("Premium 3D contract validated: shared fixed-camera stage, GL-compatible materials, and Water Sort/Rescue Rush/Block Puzzle 3D adapters are active.")
	quit(0)

func _validate_scripts_exist_and_load() -> bool:
	for path in REQUIRED_SCRIPTS:
		if not FileAccess.file_exists(path):
			return _fail("Premium 3D script is missing: " + path)
		var script := load(path) as Script
		if script == null or not script.can_instantiate():
			return _fail("Premium 3D script cannot instantiate: " + path)
	return true

func _validate_material_contract() -> bool:
	var script := load("res://scripts/ui/premium_3d_materials.gd") as Script
	var materials = script.new()
	for method_name in [&"glossy", &"matte", &"glass", &"liquid"]:
		if not materials.has_method(method_name):
			return _fail("Premium3DMaterials is missing method: " + String(method_name))
	var glossy_material = materials.call("glossy", Color("62b6ff"))
	if not glossy_material is StandardMaterial3D:
		return _fail("Premium3DMaterials.glossy must return StandardMaterial3D")
	if glossy_material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		return _fail("Opaque premium materials must not enable transparency")
	var glass_material = materials.call("glass", Color(0.85, 0.95, 1.0, 1.0))
	if not glass_material is StandardMaterial3D or glass_material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
		return _fail("Premium3DMaterials.glass must use lightweight alpha transparency")
	materials.free()
	return true

func _validate_stage_contract() -> bool:
	var script := load("res://scripts/ui/premium_3d_stage.gd") as Script
	var stage = script.new()
	root.add_child(stage)
	for method_name in [&"configure_stage", &"content_root", &"clear_content", &"make_box", &"make_cylinder"]:
		if not stage.has_method(method_name):
			return _fail("Premium3DStage is missing method: " + String(method_name))
	stage.call("configure_stage", Color("eef6ff"), Vector3(0, 8, 10), Vector3.ZERO, 11.0)
	var camera := stage.get_node_or_null("Viewport/World/Camera3D") as Camera3D
	if camera == null:
		return _fail("Premium3DStage must expose a fixed Camera3D at Viewport/World/Camera3D")
	if camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
		return _fail("Premium 3D gameplay camera must remain orthographic/fixed")
	var light := stage.get_node_or_null("Viewport/World/KeyLight") as DirectionalLight3D
	if light == null:
		return _fail("Premium3DStage must use one shared directional key light")
	stage.queue_free()
	await process_frame
	return true

func _validate_game_stage_contracts() -> bool:
	var water = (load("res://scripts/ui/water_sort_3d_stage.gd") as Script).new()
	for method_name in [&"sync_state", &"animate_pour"]:
		if not water.has_method(method_name):
			return _fail("WaterSort3DStage is missing method: " + String(method_name))
	water.free()
	var rescue = (load("res://scripts/ui/rescue_rush_3d_stage.gd") as Script).new()
	for method_name in [&"sync_state", &"animate_escape"]:
		if not rescue.has_method(method_name):
			return _fail("RescueRush3DStage is missing method: " + String(method_name))
	rescue.free()
	var block = (load("res://scripts/ui/block_puzzle_3d_stage.gd") as Script).new()
	for method_name in [&"sync_state", &"preview_shape", &"clear_preview"]:
		if not block.has_method(method_name):
			return _fail("BlockPuzzle3DStage is missing method: " + String(method_name))
	block.free()
	return true

func _validate_active_game_wiring() -> bool:
	var requirements := {
		"res://scripts/game/water_sort_ultra_motion.gd": "water_sort_3d_stage.gd",
		"res://scripts/game/rescue_rush_motion_final.gd": "rescue_rush_3d_stage.gd",
		"res://scripts/game/block_puzzle_ultra_motion.gd": "block_puzzle_3d_stage.gd",
	}
	for path in requirements:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			return _fail("Active game script is missing: " + path)
		var source := file.get_as_text()
		if not source.contains(requirements[path]):
			return _fail("Active game is not wired to premium 3D stage: " + path)
		if not source.contains("sync_state"):
			return _fail("Active game does not synchronize its logical state into 3D: " + path)
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
