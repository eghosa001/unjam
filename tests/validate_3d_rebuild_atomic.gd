extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []

	var art = load("res://scripts/ui/unjam_3d_game_art.gd").new()
	root.add_child(art)
	await process_frame
	var old_art = art.stage
	art.call("_rebuild_stage")
	if art.stage == null or art.stage == old_art:
		failures.append("Game-card 3D rebuild leaves the viewport without a replacement stage in the same frame")
	if old_art != null and old_art.get_parent() != null:
		failures.append("Game-card 3D rebuild leaves the old stage parented during replacement")
	await process_frame

	var gameplay = load("res://scripts/ui/unjam_3d_gameplay_stage.gd").new()
	root.add_child(gameplay)
	await process_frame
	var old_gameplay = gameplay.stage
	gameplay.call("_rebuild")
	if gameplay.stage == null or gameplay.stage == old_gameplay:
		failures.append("Gameplay 3D rebuild leaves the viewport blank for a frame")
	if old_gameplay != null and old_gameplay.get_parent() != null:
		failures.append("Gameplay 3D rebuild leaves the old stage parented during replacement")
	await process_frame

	var token = load("res://scripts/ui/rescue_token.gd").new()
	root.add_child(token)
	token.call("configure", "fox", Color("#f58c42"), "gold")
	await process_frame
	if String(token.get("rescue_id")) != "fox" or String(token.get("rarity")) != "gold":
		failures.append("Rescue 2D mascot did not apply visual state atomically")
	if token.get_child_count() != 0:
		failures.append("Rescue 2D mascot created hidden renderer children")

	var piece = load("res://scripts/ui/rescue_piece_3d_button.gd").new()
	root.add_child(piece)
	await process_frame
	var old_child_count: int = int(piece.get_child_count())
	piece.configure("arrow", "right", Color("19b9ff"))
	if piece.piece_type != "arrow" or piece.direction != "right" or piece.accent != Color("19b9ff"):
		failures.append("Flat Rescue piece did not apply its new visual state immediately")
	if piece.get_child_count() != old_child_count:
		failures.append("Flat Rescue piece configure created duplicate child geometry")

	for node in [art, gameplay, token, piece]:
		if is_instance_valid(node):
			node.queue_free()

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Hybrid visual renderers rebuild/update atomically without blank or duplicate frames.")
	quit(0)
