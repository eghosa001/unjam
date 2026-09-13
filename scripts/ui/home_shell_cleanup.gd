extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var main := get_parent()
	if main == null:
		return
	var premium := main.get_node_or_null("PremiumHome")
	var shell := main.get_node_or_null("UXShell")
	if premium == null or shell == null:
		return
	var shell_logo = shell.get("logo")
	if shell_logo != null and is_instance_valid(shell_logo):
		shell_logo.visible = not premium.visible
