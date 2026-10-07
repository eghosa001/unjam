class_name UnjamGameplayArt
extends Control

# Static, low-cost game-world illustration that sits behind the interactive
# controls. It gives each game an authored visual world without 3D or shaders.
var kind := ""
var accent := Color.WHITE
var dark_mode := true
var seed_value := 0

func configure(value: String, color: Color, dark: bool = true, seed: int = 0) -> void:
	kind = value
	accent = color
	dark_mode = dark
	seed_value = seed
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	match kind:
		"rescue_board":
			_draw_rescue_board()
		"water_stage":
			_draw_water_stage()
		"block_tray":
			_draw_block_tray()
		_:
			_draw_block_board()

func _draw_rescue_board() -> void:
	var w := size.x
	var h := size.y
	# Forest-floor depth: broad organic shapes, not another panel/grid.
	_oval(Vector2(w*0.05,h*0.13),Vector2(w*0.30,h*0.24),Color("#2f7654",0.30))
	_oval(Vector2(w*0.93,h*0.18),Vector2(w*0.34,h*0.28),Color("#1c6347",0.30))
	_oval(Vector2(w*0.10,h*0.88),Vector2(w*0.38,h*0.25),Color("#164d3c",0.34))
	_oval(Vector2(w*0.90,h*0.87),Vector2(w*0.36,h*0.24),Color("#34734e",0.22))

	# A luminous trail provides instant "escape route" storytelling without
	# implying a legal move or changing gameplay state.
	var trail := PackedVector2Array([
		Vector2(w*0.18,h*0.82),
		Vector2(w*0.37,h*0.64),
		Vector2(w*0.49,h*0.49),
		Vector2(w*0.67,h*0.33),
		Vector2(w*0.86,h*0.12),
	])
	draw_polyline(trail,Color(accent,0.10),maxf(18.0,w*0.07),true)
	draw_polyline(trail,Color(accent.lightened(0.34),0.20),maxf(3.0,w*0.012),true)

	# Exit portal: bright enough to read as a goal, soft enough not to look like
	# an interactive cell.
	var exit := Vector2(w*0.88,h*0.10)
	for i in range(4,0,-1):
		draw_circle(exit,w*(0.04+0.018*i),Color(accent,0.025*float(i)))
	draw_arc(exit,w*0.065,0,TAU,36,Color(accent.lightened(0.45),0.72),maxf(2.0,w*0.009),true)

	# Small foliage silhouettes create environmental texture at essentially zero
	# runtime cost.
	for p in [
		Vector2(w*0.10,h*0.18),Vector2(w*0.18,h*0.12),Vector2(w*0.83,h*0.29),
		Vector2(w*0.91,h*0.75),Vector2(w*0.16,h*0.74),Vector2(w*0.75,h*0.92)
	]:
		_draw_leaf_cluster(p,w*0.028)

func _draw_water_stage() -> void:
	var w := size.x
	var h := size.y
	var cyan := Color("#51d9ff")
	var aqua := Color("#34f0d1")
	# Underwater light shafts.
	var ray_a := PackedVector2Array([
		Vector2(w*0.08,0),Vector2(w*0.26,0),Vector2(w*0.48,h),Vector2(w*0.29,h)
	])
	var ray_b := PackedVector2Array([
		Vector2(w*0.58,0),Vector2(w*0.74,0),Vector2(w*0.66,h),Vector2(w*0.52,h)
	])
	draw_colored_polygon(ray_a,Color(cyan,0.035))
	draw_colored_polygon(ray_b,Color(aqua,0.025))
	# Soft bottle-stage pools make objects feel grounded rather than floating.
	for x in [0.18,0.39,0.61,0.82]:
		_oval(Vector2(w*x,h*0.76),Vector2(w*0.09,h*0.025),Color("#6fe8ff",0.07))
	# Bubbles kept away from the interaction core.
	var bubbles := [
		[0.10,0.20,0.010],[0.15,0.34,0.006],[0.88,0.20,0.008],
		[0.91,0.38,0.013],[0.08,0.58,0.007],[0.86,0.70,0.006],
		[0.13,0.83,0.012],[0.92,0.88,0.009]
	]
	for b in bubbles:
		var center := Vector2(w*float(b[0]),h*float(b[1]))
		var r := w*float(b[2])
		draw_circle(center,r,Color(0.78,0.97,1.0,0.035))
		draw_arc(center,r,0,TAU,18,Color(0.78,0.97,1.0,0.16),maxf(1.0,w*0.003),true)

func _draw_block_board() -> void:
	var w := size.x
	var h := size.y
	# Large color fields behind the grid make the board feel like a game surface
	# while leaving empty cells visually quiet.
	var glow_a := accent.lightened(0.18)
	_oval(Vector2(w*0.15,h*0.16),Vector2(w*0.34,h*0.24),Color(glow_a,0.055))
	_oval(Vector2(w*0.88,h*0.78),Vector2(w*0.40,h*0.30),Color("#ff4f82",0.025))
	_oval(Vector2(w*0.82,h*0.18),Vector2(w*0.30,h*0.24),Color("#39c6ff",0.025))
	# Sparse star-dust gives the field depth without competing with blocks.
	for p in [
		Vector2(w*0.12,h*0.10),Vector2(w*0.73,h*0.09),Vector2(w*0.91,h*0.40),
		Vector2(w*0.08,h*0.62),Vector2(w*0.24,h*0.90),Vector2(w*0.80,h*0.88)
	]:
		draw_circle(p,maxf(1.0,w*0.005),Color(1,1,1,0.10))

func _draw_block_tray() -> void:
	var w := size.x
	var h := size.y
	for x in [0.18,0.50,0.82]:
		_oval(Vector2(w*x,h*0.52),Vector2(w*0.16,h*0.30),Color(accent,0.045))
		draw_arc(Vector2(w*x,h*0.52),w*0.105,0,TAU,28,Color(accent.lightened(0.34),0.07),2.0,true)

func _draw_leaf_cluster(center: Vector2, r: float) -> void:
	for i in range(5):
		var a := -1.15 + float(i)*0.58
		var p := center + Vector2(cos(a),sin(a))*r*0.55
		_oval(p,Vector2(r*0.72,r*0.32),Color("#6fcf7c",0.10 + float(i%2)*0.03),a)

func _oval(center: Vector2, radii: Vector2, color: Color, rotation_angle: float = 0.0) -> void:
	var points := PackedVector2Array()
	var ca := cos(rotation_angle)
	var sa := sin(rotation_angle)
	for i in range(28):
		var a := TAU*float(i)/28.0
		var local := Vector2(cos(a)*radii.x,sin(a)*radii.y)
		var rotated := Vector2(local.x*ca-local.y*sa,local.x*sa+local.y*ca)
		points.append(center+rotated)
	draw_colored_polygon(points,color)
