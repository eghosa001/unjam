extends SceneTree

func _initialize() -> void:
	var source := _read("res://scripts/ui/ui_touch_enhancer.gd")
	for token in [
		"func _inside_authored_figma(node: Node) -> bool:",
		'cursor is FigmaReferenceCanvas or cursor.has_meta("unjam_figma_reference_root")',
		"if _inside_authored_figma(node):",
	]:
		if not source.contains(token):
			push_error("Touch enhancer Figma protection missing: %s" % token)
			quit(1)
			return

	var start := source.find("func _on_node_added")
	var finish := source.find("\nfunc ", start + 1)
	var block := source.substr(start, finish - start)
	if block.find("if _inside_authored_figma(node):") < 0:
		push_error("Live node-added path does not guard authored Figma buttons")
		quit(1)
		return
	if block.find("if _inside_authored_figma(node):") > block.find("_apply_button_size(node as Button)"):
		push_error("Figma guard must run before live button resizing")
		quit(1)
		return

	# Navigation, retry, adverts and monetization must activate on release:
	# tapping down and then scrolling away must not trigger an irreversible action.
	var fast_script := load("res://scripts/ui/ui_touch_enhancer_casual.gd") as Script
	if fast_script == null:
		push_error("Casual touch enhancer is missing")
		quit(1)
		return
	var enhancer = fast_script.new()
	for title in ["BACK","RETRY","BUY COINS","RESTORE PURCHASES","WATCH AD","NEXT LEVEL"]:
		var action := Button.new()
		action.text = title
		action.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		enhancer.call("_apply_fast_action_mode", action)
		if action.action_mode != BaseButton.ACTION_MODE_BUTTON_RELEASE:
			push_error("Touch-down prematurely activates %s" % title)
			action.free()
			enhancer.free()
			quit(1)
			return
		action.free()
	enhancer.free()

	print("TOUCH_ENHANCER_FIGMA_HITBOX_GUARD_OK")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
