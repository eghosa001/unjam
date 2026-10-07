class_name UnjamMetaArt
extends Control

# Static illustrated anchors for meta screens. These sit behind the information
# layer so the page has a game-world identity without sacrificing navigation.
var kind := ""
var dark_mode := false

func configure(surface: String, dark: bool) -> void:
	kind = surface
	dark_mode = dark
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	match kind:
		"compete":
			_draw_compete()
		"friends":
			_draw_friends()
		"goals":
			_draw_goals()
		"profile":
			_draw_profile()
		"collection":
			_draw_collection()
		"daily":
			_draw_daily()

func _draw_compete() -> void:
	var w := size.x
	var h := size.y
	var gold := Color("#ffd34e")
	var purple := Color("#8d63ff")
	_glow(Vector2(w*0.82,h*0.18),w*0.28,Color(gold,0.10))
	_glow(Vector2(w*0.12,h*0.70),w*0.42,Color(purple,0.07))
	var base_y := h*0.78
	var bw := w*0.13
	var gap := w*0.018
	_draw_podium(Rect2(Vector2(w*0.68,base_y-h*0.13),Vector2(bw,h*0.13)),2,Color("#9e72ff"))
	_draw_podium(Rect2(Vector2(w*0.68+bw+gap,base_y-h*0.19),Vector2(bw,h*0.19)),1,gold)
	_draw_podium(Rect2(Vector2(w*0.68+(bw+gap)*2,base_y-h*0.10),Vector2(bw,h*0.10)),3,Color("#4cc6ff"))
	var trophy := Vector2(w*0.83,h*0.20)
	_draw_trophy(trophy,minf(w,h)*0.075,gold)

func _draw_friends() -> void:
	var w := size.x
	var h := size.y
	_glow(Vector2(w*0.82,h*0.20),w*0.30,Color("#7a57e0",0.10))
	_glow(Vector2(w*0.10,h*0.72),w*0.36,Color("#32c8ff",0.06))
	var r := minf(w,h)*0.055
	var a := Vector2(w*0.76,h*0.19)
	var b := Vector2(w*0.88,h*0.23)
	_draw_avatar(a,r,Color("#47c9ff"),Color("#ffe08a"))
	_draw_avatar(b,r,Color("#9b6cff"),Color("#ff9f77"))
	var ribbon_y := h*0.31
	var ribbon := PackedVector2Array([
		Vector2(w*0.69,ribbon_y),Vector2(w*0.96,ribbon_y),
		Vector2(w*0.91,ribbon_y+h*0.04),Vector2(w*0.96,ribbon_y+h*0.08),
		Vector2(w*0.69,ribbon_y+h*0.08),Vector2(w*0.74,ribbon_y+h*0.04),
	])
	draw_colored_polygon(ribbon,Color("#7a57e0",0.58))
	_draw_star(Vector2(w*0.825,ribbon_y+h*0.04),r*0.48,Color("#ffe16a",0.88))

func _draw_goals() -> void:
	var w := size.x
	var h := size.y
	var orange := Color("#ff9b38")
	var gold := Color("#ffd85c")
	_glow(Vector2(w*0.82,h*0.20),w*0.30,Color(orange,0.10))
	var chest := Rect2(Vector2(w*0.72,h*0.13),Vector2(w*0.21,h*0.13))
	_round(Rect2(chest.position+Vector2(0,h*0.012),chest.size),Color(0.05,0.04,0.08,0.18),minf(chest.size.x,chest.size.y)*0.14)
	_round(chest,Color("#d76b2f",0.80),minf(chest.size.x,chest.size.y)*0.14,Color(gold,0.72),2)
	draw_line(Vector2(chest.position.x,chest.position.y+chest.size.y*0.42),Vector2(chest.end.x,chest.position.y+chest.size.y*0.42),Color(gold,0.70),2.0,true)
	_round(Rect2(chest.get_center()-Vector2(w*0.022,h*0.015),Vector2(w*0.044,h*0.030)),gold,5)
	var points := PackedVector2Array([
		Vector2(w*0.10,h*0.70),Vector2(w*0.28,h*0.62),Vector2(w*0.46,h*0.69),
		Vector2(w*0.64,h*0.60),Vector2(w*0.83,h*0.67),
	])
	draw_polyline(points,Color(orange,0.15),maxf(5.0,w*0.018),true)
	for i in range(points.size()):
		draw_circle(points[i],maxf(4.0,w*0.017),Color(gold,0.30 if i<points.size()-1 else 0.58))
		if i < points.size()-1:
			_draw_star(points[i],maxf(2.0,w*0.008),Color("#fff1a1",0.54))

func _draw_profile() -> void:
	var w := size.x
	var h := size.y
	var violet := Color("#8a64ef")
	var blue := Color("#39bfff")
	_glow(Vector2(w*0.82,h*0.20),w*0.31,Color(violet,0.10))
	var center := Vector2(w*0.83,h*0.21)
	var r := minf(w,h)*0.085
	var shield := PackedVector2Array([
		center+Vector2(-r*0.78,-r),center+Vector2(r*0.78,-r),
		center+Vector2(r*0.66,r*0.24),center+Vector2(0,r),
		center+Vector2(-r*0.66,r*0.24),
	])
	draw_colored_polygon(shield,Color(violet,0.66))
	var outline := PackedVector2Array([shield[0],shield[1],shield[2],shield[3],shield[4],shield[0]])
	draw_polyline(outline,Color("#d8c8ff",0.72),maxf(1.5,r*0.08),true)
	draw_circle(center-Vector2(0,r*0.22),r*0.25,Color("#ffe09b",0.86))
	draw_arc(center+Vector2(0,r*0.32),r*0.40,PI,TAU,22,Color(blue,0.88),maxf(3.0,r*0.18),true)
	for i in range(3):
		_draw_star(Vector2(w*(0.70+0.10*i),h*0.34),r*0.20,Color("#ffd85c",0.48+0.10*i))

func _draw_collection() -> void:
	var w := size.x
	var h := size.y
	var green := Color("#32c978")
	var mint := Color("#8cf0b6")
	_glow(Vector2(w*0.82,h*0.18),w*0.34,Color(green,0.10))
	# A soft garden scene sits behind the lower Collection information.
	var hill := PackedVector2Array()
	hill.append(Vector2(-w*0.10,h*0.78))
	for i in range(17):
		var x := -w*0.10 + w*1.20*float(i)/16.0
		var y := h*(0.77 + 0.035*sin(float(i)*0.62))
		hill.append(Vector2(x,y))
	hill.append(Vector2(w*1.10,h))
	hill.append(Vector2(-w*0.10,h))
	draw_colored_polygon(hill,Color(green,0.08 if dark_mode else 0.11))
	var trunk_x := w*0.83
	draw_rect(Rect2(Vector2(trunk_x-w*0.014,h*0.63),Vector2(w*0.028,h*0.13)),Color("#8b5b3f",0.38),true)
	for p in [Vector2(w*0.79,h*0.61),Vector2(w*0.86,h*0.60),Vector2(w*0.82,h*0.55)]:
		draw_circle(p,w*0.075,Color(mint,0.18))
	var fountain := Vector2(w*0.16,h*0.74)
	draw_arc(fountain,w*0.055,PI,TAU,22,Color("#61d9ff",0.30),3.0,true)
	draw_line(fountain-Vector2(0,h*0.07),fountain,Color("#61d9ff",0.24),3.0,true)
	for i in range(4):
		_draw_star(Vector2(w*(0.27+0.13*i),h*(0.70+0.025*(i%2))),w*0.012,Color("#ffe071",0.30))

func _draw_daily() -> void:
	var w := size.x
	var h := size.y
	var gold := Color("#ffd85a")
	_glow(Vector2(w*0.82,h*0.20),w*0.29,Color(gold,0.09))
	var center := Vector2(w*0.84,h*0.20)
	_draw_star(center,w*0.075,Color(gold,0.68))
	for i in range(3):
		var c := Vector2(w*(0.70+0.10*i),h*0.31)
		draw_circle(c,w*0.026,Color("#7a57e0",0.30+0.08*i))
		draw_arc(c,w*0.034,0,TAU,24,Color(gold,0.28),2.0,true)

func _draw_podium(rect: Rect2, place: int, color: Color) -> void:
	_round(Rect2(rect.position+Vector2(0,4),rect.size),Color(0.02,0.03,0.07,0.14),8)
	_round(rect,Color(color,0.50),8,Color(color.lightened(0.26),0.34),1)
	var text_pos := rect.get_center()+Vector2(-4,5)
	draw_string(ThemeDB.fallback_font,text_pos,str(place),HORIZONTAL_ALIGNMENT_CENTER,-1,12,Color(1,1,1,0.70))

func _draw_trophy(center: Vector2, r: float, color: Color) -> void:
	var cup := Rect2(center-Vector2(r*0.52,r*0.65),Vector2(r*1.04,r*0.72))
	_round(cup,Color(color,0.74),r*0.18,Color("#fff0a5",0.54),1)
	draw_arc(center+Vector2(-r*0.56,-r*0.30),r*0.32,PI*0.52,PI*1.48,18,Color(color,0.60),maxf(2.0,r*0.11),true)
	draw_arc(center+Vector2(r*0.56,-r*0.30),r*0.32,-PI*0.48,PI*0.48,18,Color(color,0.60),maxf(2.0,r*0.11),true)
	draw_line(center+Vector2(0,r*0.05),center+Vector2(0,r*0.55),Color(color,0.72),maxf(2.0,r*0.13),true)
	_round(Rect2(center+Vector2(-r*0.42,r*0.48),Vector2(r*0.84,r*0.20)),Color(color,0.70),r*0.08)

func _draw_avatar(center: Vector2, r: float, body: Color, face: Color) -> void:
	draw_circle(center,r,Color(body,0.52))
	draw_circle(center-Vector2(0,r*0.18),r*0.42,Color(face,0.76))
	draw_arc(center+Vector2(0,r*0.52),r*0.53,PI,TAU,18,Color(body.lightened(0.28),0.74),maxf(2.0,r*0.22),true)

func _glow(center: Vector2, radius: float, color: Color) -> void:
	for i in range(5,0,-1):
		var t := float(i)/5.0
		draw_circle(center,radius*t,Color(color.r,color.g,color.b,color.a*(0.16+0.13*(1.0-t))))

func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		var a := -PI*0.5 + float(i)*PI/5.0
		var r := radius if i%2==0 else radius*0.44
		points.append(center+Vector2(cos(a),sin(a))*r)
	draw_colored_polygon(points,color)

func _round(rect: Rect2, fill: Color, radius: float, border: Color = Color.TRANSPARENT, border_width: int = 0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	var rr := maxi(0,int(round(radius)))
	style.corner_radius_top_left = rr
	style.corner_radius_top_right = rr
	style.corner_radius_bottom_left = rr
	style.corner_radius_bottom_right = rr
	if border_width > 0:
		style.border_width_left = border_width
		style.border_width_top = border_width
		style.border_width_right = border_width
		style.border_width_bottom = border_width
		style.border_color = border
	draw_style_box(style,rect)
