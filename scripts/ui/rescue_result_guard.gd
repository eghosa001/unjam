extends Node

var host: Control

func _ready() -> void:
	host = get_parent() as Control
	if host == null:
		return
	host.child_entered_tree.connect(_on_child_added)

func _on_child_added(node: Node) -> void:
	if host == null or node == self:
		return
	call_deferred("_inspect_child", node)

func _inspect_child(node: Node) -> void:
	if not is_instance_valid(node) or node.get_parent() != host:
		return
	# The Rescue Rush completion surface is the only direct full-screen ColorRect
	# created by the gameplay scene. Force it above launch ghosts, speed lines and
	# the rescue token so no arrow can ever bleed through the result screen.
	if node is ColorRect:
		var overlay := node as ColorRect
		overlay.z_index = 2000
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		for sibling in host.get_children():
			if sibling == overlay or sibling == self:
				continue
			if sibling is CanvasItem and (sibling as CanvasItem).z_index >= 200:
				(sibling as CanvasItem).visible = false
