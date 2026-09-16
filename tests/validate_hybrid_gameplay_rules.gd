extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	var water_script := load("res://scripts/game/water_sort_reference_motion.gd")
	var water = water_script.new()
	var plan: Dictionary = water._build_transfer_plan([[0, 1, 1], [1], []], 0, 1)
	if int(plan.get("amount", -1)) != 2:
		failures.append("Water transfer should move contiguous top colour count 2")
	if plan.get("source_after", []) != [0]:
		failures.append("Water source state did not match planned transition")
	if plan.get("target_after", []) != [1, 1, 1]:
		failures.append("Water destination state did not match planned transition")
	if not water._build_transfer_plan([[0], [2]], 0, 1).is_empty():
		failures.append("Water mismatched destination colour should be illegal")
	if not water._build_transfer_plan([[0], [0, 0, 0, 0]], 0, 1).is_empty():
		failures.append("Water full destination should be illegal")
	water.free()

	var rescue_script := load("res://scripts/game/rescue_rush_polished.gd")
	var rescue = rescue_script.new()
	rescue.width = 5
	rescue.height = 5
	var test_pieces: Array[Dictionary] = [
		{"x": 1, "y": 2, "direction": "right", "type": "normal", "active": true}
	]
	rescue.pieces = test_pieces
	var route: Array[Vector2i] = rescue._escape_route_cells(0)
	var expected: Array[Vector2i] = [
		Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2)
	]
	if route != expected:
		failures.append("Rescue route should include every board cell and first off-board endpoint")
	rescue.free()

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Hybrid gameplay rules validated: water transition planning + rescue route command.")
	quit(0)
