extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var files: Array[String] = []
	_collect_files("res://", files)
	var text_by_path: Dictionary = {}
	for path in files:
		if path.ends_with(".gd") or path.ends_with(".tscn") or path.ends_with(".tres") or path.ends_with(".godot") or path.ends_with(".cfg") or path.ends_with(".py") or path.ends_with(".sh") or path.ends_with(".yml") or path.ends_with(".yaml"):
			text_by_path[path] = FileAccess.get_file_as_string(path)

	var candidates: Array[Dictionary] = []
	for path in files:
		if not path.ends_with(".gd"):
			continue
		if path.begins_with("res://tests/") or path.begins_with("res://tools/") or path.begins_with("res://addons/"):
			continue
		var own := String(text_by_path.get(path, ""))
		var class_id := _class_name(own)
		var path_refs := 0
		var class_refs := 0
		for other_path in text_by_path.keys():
			if String(other_path) == path:
				continue
			var other := String(text_by_path[other_path])
			path_refs += other.count(path)
			if not class_id.is_empty():
				class_refs += _word_count(other, class_id)
		if path_refs == 0 and class_refs == 0:
			candidates.append({
				"path": path,
				"class_name": class_id,
				"lines": own.split("\n").size()
			})

	print("DEAD_CODE_CANDIDATE_COUNT=%d" % candidates.size())
	for candidate in candidates:
		print("DEAD_CODE_CANDIDATE %s class=%s lines=%d" % [
			String(candidate.path),
			String(candidate.class_name),
			int(candidate.lines)
		])
	print("DEAD_CODE_REACHABILITY_AUDIT_OK")
	quit(0)

func _collect_files(root_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(root_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if name in [".git", ".godot"]:
			continue
		var path := root_path.path_join(name)
		if dir.current_is_dir():
			_collect_files(path, out)
		else:
			out.append(path)
	dir.list_dir_end()

func _class_name(content: String) -> String:
	for line in content.split("\n"):
		var stripped := String(line).strip_edges()
		if stripped.begins_with("class_name "):
			return stripped.trim_prefix("class_name ").strip_edges().split(" ")[0]
	return ""

func _word_count(content: String, token: String) -> int:
	if token.is_empty():
		return 0
	var count := 0
	var start := 0
	while true:
		var idx := content.find(token, start)
		if idx < 0:
			break
		var left_ok := idx == 0 or not _is_word_char(content.unicode_at(idx - 1))
		var end := idx + token.length()
		var right_ok := end >= content.length() or not _is_word_char(content.unicode_at(end))
		if left_ok and right_ok:
			count += 1
		start = end
	return count

func _is_word_char(codepoint: int) -> bool:
	return (
		(codepoint >= 48 and codepoint <= 57)
		or (codepoint >= 65 and codepoint <= 90)
		or (codepoint >= 97 and codepoint <= 122)
		or codepoint == 95
	)
