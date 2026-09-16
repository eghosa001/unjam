extends Node

# Keeps interactive top-level surfaces inside the OS-reported safe area while
# allowing the Main root itself to remain full-screen. The Android safe area is
# reported in physical display pixels; UNJAM renders in a logical stretched
# viewport, so the margins are converted before being applied.
signal safe_area_changed(safe_margins: Vector4)

var safe_margins := Vector4.ZERO
var _last_viewport_size := Vector2.ZERO
var _last_safe_margins := Vector4(-1, -1, -1, -1)

func _ready() -> void:
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_changed):
		viewport.size_changed.connect(_on_viewport_changed)
	var host := get_parent()
	if host != null:
		if not host.child_entered_tree.is_connected(_on_host_child_entered):
			host.child_entered_tree.connect(_on_host_child_entered)
		if host.has_signal("surface_changed") and not host.surface_changed.is_connected(_on_surface_changed):
			host.surface_changed.connect(_on_surface_changed)
	call_deferred("refresh")

func refresh() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var logical_rect := viewport.get_visible_rect()
	if logical_rect.size.x <= 0.0 or logical_rect.size.y <= 0.0:
		return
	_last_viewport_size = logical_rect.size
	safe_margins = _calculate_safe_margins(logical_rect.size)
	_apply_to_host_surfaces()
	if not safe_margins.is_equal_approx(_last_safe_margins):
		_last_safe_margins = safe_margins
		safe_area_changed.emit(safe_margins)

func content_rect() -> Rect2:
	var viewport := get_viewport()
	var size := viewport.get_visible_rect().size if viewport != null else _last_viewport_size
	return Rect2(
		Vector2(safe_margins.x, safe_margins.y),
		Vector2(
			maxf(0.0, size.x - safe_margins.x - safe_margins.z),
			maxf(0.0, size.y - safe_margins.y - safe_margins.w)
		)
	)

func _calculate_safe_margins(logical_size: Vector2) -> Vector4:
	# Headless/desktop environments can return an empty safe area. In that case
	# there is no cutout to compensate for and all margins stay zero.
	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	var screen_index := DisplayServer.window_get_current_screen()
	var physical_size: Vector2i = DisplayServer.screen_get_size(screen_index)
	if physical_size.x <= 0 or physical_size.y <= 0 or safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return Vector4.ZERO

	var sx := logical_size.x / float(physical_size.x)
	var sy := logical_size.y / float(physical_size.y)
	var left := maxf(0.0, float(safe_rect.position.x) * sx)
	var top := maxf(0.0, float(safe_rect.position.y) * sy)
	var right_px := max(0, physical_size.x - safe_rect.end.x)
	var bottom_px := max(0, physical_size.y - safe_rect.end.y)
	var right := float(right_px) * sx
	var bottom := float(bottom_px) * sy

	# Guard against bogus vendor/display reports. A safe inset should never consume
	# more than one quarter of either dimension for this portrait phone UI.
	left = minf(left, logical_size.x * 0.25)
	right = minf(right, logical_size.x * 0.25)
	top = minf(top, logical_size.y * 0.25)
	bottom = minf(bottom, logical_size.y * 0.25)
	return Vector4(left, top, right, bottom)

func _apply_to_host_surfaces() -> void:
	var host := get_parent()
	if host == null:
		return
	for child in host.get_children():
		if child is Control:
			_apply_safe_margins(child as Control)

func _apply_safe_margins(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	# Only direct full-screen surfaces are adjusted. Their internal layout remains
	# responsible for its own spacing and aspect-ratio adaptation.
	control.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	control.offset_left = safe_margins.x
	control.offset_top = safe_margins.y
	control.offset_right = -safe_margins.z
	control.offset_bottom = -safe_margins.w

func _on_viewport_changed() -> void:
	call_deferred("refresh")

func _on_surface_changed(_surface = null) -> void:
	call_deferred("refresh")

func _on_host_child_entered(node: Node) -> void:
	if node is Control:
		call_deferred("_fit_if_alive", node)

func _fit_if_alive(node: Node) -> void:
	if node is Control and is_instance_valid(node) and node.get_parent() == get_parent():
		_apply_safe_margins(node as Control)
