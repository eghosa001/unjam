extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var main := get_parent()
	if main == null:
		return
	var shell := main.get_node_or_null("UXShell")
	if shell == null:
		return
	# PremiumHome owns branding. The shell icon must never be shown on gameplay,
	# level-select, settings, collection, or any other navigable surface because
	# it collides with the real top-left back affordance on phones.
	var shell_logo = shell.get("logo")
	if shell_logo != null and is_instance_valid(shell_logo):
		shell_logo.visible = false
