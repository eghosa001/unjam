extends "res://scripts/ui/water_tube_reference_button.gd"

const MATERIALS_SCRIPT = preload("res://scripts/ui/procedural_materials.gd")

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

func visual_pour_rim_local(direction: float) -> Vector2:
	# Match the exact lip drawn in _draw(). The stream must begin on the outside
	# edge of the visible glass mouth, never from the tube centre.
	var lift := -13.0 if is_selected and pour_mode == 0 else 0.0
	var outer := Rect2(Vector2(size.x * 0.18, 13.0 + lift), Vector2(size.x * 0.64, size.y - 42.0))
	var neck_h := outer.size.y * 0.10
	var body := Rect2(outer.position + Vector2(0, neck_h * 0.40), Vector2(outer.size.x, outer.size.y - neck_h * 0.40))
	var dir := 1.0 if direction >= 0.0 else -1.0
	return Vector2(body.get_center().x + dir * body.size.x * 0.50, body.position.y + 3.0)

func visual_receive_rim_local() -> Vector2:
	var outer := Rect2(Vector2(size.x * 0.18, 13.0), Vector2(size.x * 0.64, size.y - 42.0))
	var neck_h := outer.size.y * 0.10
	var body := Rect2(outer.position + Vector2(0, neck_h * 0.40), Vector2(outer.size.x, outer.size.y - neck_h * 0.40))
	return Vector2(body.get_center().x, body.position.y + 3.0)

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
	var lift := -13.0 if is_selected and pour_mode == 0 else 0.0
	var outer := Rect2(Vector2(size.x * 0.18, 13.0 + lift), Vector2(size.x * 0.64, size.y - 42.0))
	var neck_h := outer.size.y * 0.10
	var body := Rect2(outer.position + Vector2(0, neck_h * 0.40), Vector2(outer.size.x, outer.size.y - neck_h * 0.40))
	var inner := Rect2(body.position + Vector2(7, 10), body.size - Vector2(14, 20))
	var radius := minf(18.0, body.size.x * 0.30)
	var reduced := MotionSystem.reduced()
	var depth_offset := _materials.extrusion_offset(0.70, reduced)
	var glass_depth := _materials.depth_tone(Color(0.56, 0.82, 1.0, 0.17), 0.72)
	_draw_glass_shape(Rect2(body.position + depth_offset, body.size), glass_depth, Color.TRANSPARENT, radius, 0.0)
	_draw_glass_shape(Rect2(body.position + depth_offset + Vector2(0, 5), body.size), _materials.contact_shadow(0.18), Color.TRANSPARENT, radius, 0.0)
	var outline := Color(1, 1, 1, 0.82)
	if is_selected and pour_mode == 0: outline = Color("fff3b4")
	if invalid_flash > 0.0: outline = Color("ff4d67")
	if success_flash > 0.0: outline = Color("7ff0b0")
	var front_glass := Color(1, 1, 1, 0.045)
	_draw_glass_shape(body, front_glass, outline, radius, 3.0)
	var bevel_light: Color = _materials.bevel_light(Color(0.72, 0.91, 1.0, 0.44), 0.72)
	var bevel_dark: Color = _materials.bevel_dark(Color(0.54, 0.76, 0.94, 0.34), 0.78)
	draw_line(Vector2(body.position.x + 4, body.position.y + 8), Vector2(body.end.x - 4, body.position.y + 8), bevel_light, 2.0, true)
	draw_line(Vector2(body.position.x + 8, body.end.y - 6), Vector2(body.end.x - 8, body.end.y - 6), bevel_dark, 2.0, true)
	var slot_h := inner.size.y / float(CAPACITY)
	for slot in range(CAPACITY):
		var fraction := _slot_fill(slot)
		if fraction <= 0.001: continue
		var liquid: Color = PALETTE[_slot_color(slot)]
		var y := inner.end.y - slot_h * float(slot + 1)
		var r := Rect2(Vector2(inner.position.x, y + 1.0), Vector2(inner.size.x, slot_h + 1.0))
		r.position.y += r.size.y * (1.0 - fraction)
		r.size.y *= fraction
		var wave_strength := 0.0 if reduced else 2.0 * slosh
		var wave := sin(pulse * 10.0 + float(slot) * 1.7) * wave_strength
		r.position.y += wave
		var lower_color := _materials.vertical_shade(liquid, 0.76)
		var upper_color := _materials.vertical_shade(liquid, 0.20)
		var liquid_depth: Color = _materials.depth_tone(liquid, 0.68)
		var liquid_depth_offset := Vector2(0, minf(3.0, maxf(1.0, r.size.y * 0.10)))
		if r.size.y > 4.0:
			draw_rect(Rect2(r.position + liquid_depth_offset, r.size), Color(liquid_depth, liquid.a * 0.72), true)
		if slot == 0:
			var style := StyleBoxFlat.new()
			style.bg_color = lower_color
			style.corner_radius_bottom_left = int(radius * 0.52)
			style.corner_radius_bottom_right = int(radius * 0.52)
			draw_style_box(style, r)
		else:
			draw_rect(r, lower_color, true)
		# A translucent top-light strip creates a cheap vertical material ramp
		# without requiring shaders and stays crisp under GL Compatibility.
		var light_h := minf(7.0, r.size.y * 0.28)
		if light_h > 1.0:
			draw_rect(Rect2(r.position, Vector2(r.size.x, light_h)), Color(upper_color, 0.48), true)
		draw_line(Vector2(r.position.x + 2, r.position.y + 2), Vector2(r.end.x - 2, r.position.y + 2 - wave * 0.3), _materials.bevel_light(upper_color, 0.55), 2.0, true)
	var lip_y := body.position.y + 3.0
	draw_line(Vector2(body.position.x - 3, lip_y), Vector2(body.end.x + 3, lip_y), outline, 4.0, true)
	var specular_alpha := 0.28
	var specular_shift := 0.0 if reduced else sin(pulse * 0.85) * 2.0
	draw_line(Vector2(body.position.x + 9 + specular_shift, body.position.y + 18), Vector2(body.position.x + 9 + specular_shift, body.end.y - 24), _materials.glass_highlight(Color.WHITE, specular_alpha), 3.0, true)
	draw_line(Vector2(body.end.x - 7, body.position.y + 23), Vector2(body.end.x - 7, body.size.y * 0.38 + body.position.y), Color(1, 1, 1, 0.13), 2.0, true)
	if is_selected and pour_mode == 0:
		var a := 0.35 if reduced else 0.35 + 0.12 * sin(pulse * 5.0)
		draw_arc(body.get_center(), body.size.x * 0.68, 0, TAU, 42, Color(1.0, 0.88, 0.35, a), 4.0, true)
