extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/ui/main.gd", FileAccess.READ)
	if file == null:
		push_error("Main UI source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	var start := source.find("func clear_content()")
	var finish := source.find("\nfunc ", start + 1)
	var block := source.substr(start, finish - start if finish > start else source.length() - start)
	var detach := block.find("remove_child(content)")
	var free := block.find("content.queue_free()")
	if detach < 0 or free < 0 or detach > free:
		push_error("Old full-screen content is not detached before deferred deletion")
		quit(1)
		return
	print("Main surface replacement is atomic.")
	quit(0)
