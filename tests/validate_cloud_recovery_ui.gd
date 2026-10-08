extends SceneTree

const SIZES := [Vector2i(432, 936), Vector2i(540, 960), Vector2i(1200, 1920)]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var popup_script := load("res://scripts/ui/cloud_recovery_dialog.gd")
	if packed == null or popup_script == null:
		_fail("Cloud recovery popup or main scene unavailable")
		return
	for size_value in SIZES:
		root.size = size_value
		var main := packed.instantiate() as Control
		root.add_child(main)
		main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for _i in range(6):
			await process_frame
		var popup: Node = popup_script.new()
		main.add_child(popup)
		for _i in range(4):
			await process_frame
		var scroll := popup.get_node_or_null("CloudRecoveryCenter/CloudRecoveryScroll") as ScrollContainer
		if scroll == null:
			_fail("Scrollable recovery window did not render")
			return
		var card := scroll.get_node_or_null("CloudRecoveryCard") as Control
		if card == null:
			_fail("Recovery card missing inside scroll window")
			return
		var area := Rect2(Vector2.ZERO, Vector2(size_value))
		if not area.encloses(scroll.get_global_rect()):
			_fail("Recovery scroll window escapes screen at %s: %s" % [str(size_value), str(scroll.get_global_rect())])
			return
		if popup.get_node_or_null("CloudRecoveryCenter/CloudRecoveryScroll/CloudRecoveryCard/MarginContainer/VBoxContainer/RecoveryCodeInput") == null:
			_fail("Recovery code entry is missing")
			return
		popup.queue_free()
		main.queue_free()
		await process_frame
	print("CLOUD_RECOVERY_UI_OK: card, input and readable viewport placement.")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
