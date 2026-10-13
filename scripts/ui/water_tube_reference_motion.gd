extends "res://scripts/ui/water_tube_reference_button.gd"

const MATERIALS_SCRIPT = preload("res://scripts/ui/procedural_materials.gd")
const AUTHORED_GLASS_OVERLAY: Texture2D = preload("res://assets/art/gameplay/water_glass_overlay.svg")

var pour_mode := 0
var pour_color := 0
var pour_amount := 0
var pour_progress := 0.0
var slosh := 0.0
var _materials = MATERIALS_SCRIPT.new()

func begin_pour_out(amount: int) -> void:
	pour_mode = -1
	pour_amount = clampi(amount, 0, layers.size())
	pour_color = int(layers.back()) if not layers.is_empty() else 0
	pour_progress = 0.0
	slosh = 1.0
	queue_redraw()

func begin_pour_in(color_index: int, amount: int) -> void:
	pour_mode = 1
	pour_color = clampi(color_index, 0, PALETTE.size() - 1)
	pour_amount = clampi(amount, 0, CAPACITY - layers.size())
	pour_progress = 0.0
	slosh = 1.0
	queue_redraw()

func set_pour_progress(value: float) -> void:
	pour_progress = clampf(value, 0.0, 1.0)
	queue_redraw()

func _motion_body_rect() -> Rect2:
	# Share the same bottle geometry between rendering and rim positioning.
	var lift := -13.0 if is_selected and pour_mode == 0 else 0.0
	var outer := Rect2(Vector2(size.x * 0.13, 13.0 + lift), Vector2(size.x * 0.74, size.y - 42.0))
	var neck_h := outer.size.y * 0.10
	return Rect2(outer.position + Vector2(0, neck_h * 0.40), Vector2(outer.size.x, outer.size.y - neck_h * 0.40))

func _motion_mouth_center() -> Vector2:
	var body := _motion_body_rect()
	var neck_height := maxf(12.0, body.size.y * 0.125)
	return Vector2(body.get_center().x, body.position.y - neck_height * 0.38 + 1.5)

func visual_pour_rim_local(direction: float) -> Vector2:
	# The stream must leave the narrow glass neck, not the broad body shoulder.
	var body := _motion_body_rect()
	var dir := 1.0 if direction >= 0.0 else -1.0
	return _motion_mouth_center() + Vector2(dir * (body.size.x * 0.24 + 1.5), 0.0)

func visual_receive_rim_local() -> Vector2:
	return _motion_mouth_center()

func _slot_fill(slot: int) -> float:
	if pour_mode == -1 and pour_amount > 0:
		var first := layers.size() - pour_amount
		if slot >= first and slot < layers.size():
			return clampf(float(pour_amount) * (1.0 - pour_progress) - float(slot - first), 0.0, 1.0)
	if slot < layers.size():
		return 1.0
	if pour_mode == 1 and pour_amount > 0:
		var local := slot - layers.size()
		if local >= 0 and local < pour_amount:
			return clampf(float(pour_amount) * pour_progress - float(local), 0.0, 1.0)
	return 0.0

func _slot_color(slot: int) -> int:
	if slot < layers.size():
		return clampi(int(layers[slot]), 0, PALETTE.size() - 1)
	return pour_color

func _process(delta: float) -> void:
	super._process(delta)
	var slosh_decay := 3.8 if MotionSystem.reduced() else 1.5
	slosh = maxf(0.0, slosh - delta * slosh_decay)
	if pour_mode != 0 or slosh > 0.001:
		queue_redraw()

func _draw() -> void:
	var body := _motion_body_rect()
	var inner := Rect2(body.position + Vector2(5, 10), body.size - Vector2(10, 20))
	var radius := minf(20.0, body.size.x * 0.31)
	_draw_glass_shape(Rect2(body.position + Vector2(0, 8), body.size), _materials.contact_shadow(0.20), Color.TRANSPARENT, radius, 0.0)
	var outline := Color(1, 1, 1, 0.82)
	if is_selected and pour_mode == 0: outline = Color("fff3b4")
	if invalid_flash > 0.0: outline = Color("ff4d67")
	if success_flash > 0.0: outline = Color("7ff0b0")
	_draw_glass_shape(body, Color(0.74, 0.95, 1.0, 0.055), outline, radius, 3.6)
	var slot_h := inner.size.y / float(CAPACITY)
	for slot in range(CAPACITY):
		var fraction := _slot_fill(slot)
		if fraction <= 0.001: continue
		var liquid: Color = PALETTE[_slot_color(slot)]
		var y := inner.end.y - slot_h * float(slot + 1)
		var r := Rect2(Vector2(inner.position.x, y + 1.0), Vector2(inner.size.x, slot_h + 1.0))
		r.position.y += r.size.y * (1.0 - fraction)
		r.size.y *= fraction
		var wave_strength := 0.0 if MotionSystem.reduced() else 2.0 * slosh
		var wave := sin(pulse * 10.0 + float(slot) * 1.7) * wave_strength
		r.position.y += wave
		var lower_color := _materials.vertical_shade(liquid, 0.76)
		var upper_color := _materials.vertical_shade(liquid, 0.20)
		if slot == 0:
			var style := StyleBoxFlat.new()
			style.bg_color = lower_color
			style.corner_radius_bottom_left = int(radius * 0.52)
			style.corner_radius_bottom_right = int(radius * 0.52)
			draw_style_box(style, r)
		else:
			draw_rect(r, lower_color, true)
		# Cheap cylindrical edge shading: coloured liquid now reads as a volume,
		# rather than a stack of solid rectangles. The bands share each run's
		# colour and never cover the exposed surface/meniscus.
		var side_band := clampf(r.size.x * 0.12, 2.0, 6.0)
		draw_rect(Rect2(r.position, Vector2(side_band, r.size.y)), Color(liquid.darkened(0.38), 0.23), true)
		draw_rect(Rect2(Vector2(r.end.x - side_band, r.position.y), Vector2(side_band, r.size.y)), Color(liquid.darkened(0.32), 0.17), true)
		if r.size.y >= 9.0:
			var soft_center := Rect2(Vector2(r.position.x + r.size.x * 0.40, r.position.y + 2.0), Vector2(r.size.x * 0.16, r.size.y - 4.0))
			draw_rect(soft_center, Color(1, 1, 1, 0.055), true)
		# Only the exposed liquid surface owns a highlight/meniscus line. Equal
		# adjacent colours are one body of liquid, not stacked solid layers.
		var next_fill := _slot_fill(slot + 1) if slot + 1 < CAPACITY else 0.0
		var next_color := _slot_color(slot + 1) if next_fill > 0.001 else -1
		var exposed_surface := next_fill <= 0.001 or next_color != _slot_color(slot)
		if exposed_surface:
			var light_h := minf(7.0, r.size.y * 0.28)
			if light_h > 1.0:
				draw_rect(Rect2(r.position, Vector2(r.size.x, light_h)), Color(upper_color, 0.48), true)
			draw_line(Vector2(r.position.x + 2, r.position.y + 2), Vector2(r.end.x - 2, r.position.y + 2 - wave * 0.3), upper_color.lightened(0.10), 2.0, true)
	# The lip follows the actual 48%-wide neck, not the whole body width.
	# The former long white stroke visually joined adjacent bottles on dense
	# boards and made the glass resemble a rack of flat horizontal bars.
	var lip_center := _motion_mouth_center()
	var left_rim := visual_pour_rim_local(-1.0)
	var right_rim := visual_pour_rim_local(1.0)
	draw_line(left_rim, right_rim, Color(outline, 0.86), 3.0, true)
	draw_line(left_rim + Vector2(3.0, -1.6), lip_center + Vector2(body.size.x * 0.06, -1.6), Color(1, 1, 1, 0.40), 1.4, true)
	# Break the reflection into short rim-side glints. A continuous white line
	# over the full bottle looks like plastic, especially across dark liquids.
	# Outer-edge glints keep colour runs unobstructed on narrow Android slots.
	var specular_alpha := 0.28
	var specular_shift := 0.0 if MotionSystem.reduced() else sin(pulse * 0.85) * 1.0
	var crystal_glint := _materials.glass_highlight(Color.WHITE, specular_alpha + 0.08)
	var left_edge := body.position.x + clampf(body.size.x * 0.055, 2.0, 4.0) + specular_shift
	draw_line(Vector2(left_edge, body.position.y + radius * 1.05), Vector2(left_edge, body.position.y + body.size.y * 0.32), crystal_glint, 2.6, true)
	draw_line(Vector2(left_edge + 1.5, body.end.y - radius * 1.50), Vector2(left_edge + 1.5, body.end.y - radius * 0.85), Color(1, 1, 1, 0.18), 1.8, true)
	var right_edge := body.end.x - clampf(body.size.x * 0.055, 2.0, 4.0)
	draw_line(Vector2(right_edge, body.position.y + radius * 1.20), Vector2(right_edge, body.position.y + body.size.y * 0.23), Color(1, 1, 1, 0.20), 1.7, true)
	draw_arc(Vector2(body.get_center().x, body.end.y - radius * 0.66), body.size.x * 0.33, 0.14, PI - 0.14, 20, Color(0.85, 0.97, 1.0, 0.22), 2.0, true)
	# Authored glass silhouette/highlight pass sits above dynamic liquid.
	draw_texture_rect(AUTHORED_GLASS_OVERLAY, body.grow(5.0), false, Color.WHITE)
	if is_selected and pour_mode == 0:
		var a := 0.35 if MotionSystem.reduced() else 0.35 + 0.12 * sin(pulse * 5.0)
		draw_arc(body.get_center(), body.size.x * 0.68, 0, TAU, 42, Color(1.0, 0.88, 0.35, a), 4.0, true)
