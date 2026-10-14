extends Control
class_name RescueGardenWorldView

# Original, procedural garden landscape. It grows with the six *actual* owned
# Collection upgrades. All drawing is static and done only on construction or
# an explicit refresh; there is no _process(), particle system or GPU scene.
var _levels: Dictionary = {}
var _total_levels := 0

func configure(levels: Dictionary) -> void:
	_levels = levels.duplicate()
	_total_levels = 0
	for key in ["tree","bench","fountain","lanterns","cottage","rainbow_bridge"]:
		_total_levels += clampi(int(_levels.get(key,0)),0,5)
	accessibility_name = "Rescue Garden: %d of 30 permanent upgrade levels" % _total_levels
	queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO,size)
	var maturity := clampf(float(_total_levels)/30.0,0.0,1.0)
	var ground := Color("#194e47").lerp(Color("#1e775a"),maturity)
	var edge := Color("#d4c6a7")
	draw_rect(bounds,Color("#102a3a"))
	draw_rect(Rect2(0,0,size.x,88),Color("#255765").lerp(Color("#34726c"),maturity))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0,87), Vector2(size.x*0.25,65), Vector2(size.x*0.58,93),
		Vector2(size.x*0.85,68), Vector2(size.x,84),
		Vector2(size.x,size.y), Vector2(0,size.y)
	]),ground)
	draw_rect(Rect2(0,0,size.x,size.y),Color("#f4dfb4",0.025))
	# The canal and stone walk form one coherent, visible neighbourhood route.
	draw_polyline(PackedVector2Array([
		Vector2(0,292),Vector2(53,283),Vector2(101,260),Vector2(146,253),
		Vector2(203,272),Vector2(268,299),Vector2(size.x,308)
	]),Color("#298cad"),17,true)
	draw_polyline(PackedVector2Array([
		Vector2(0,291),Vector2(53,282),Vector2(101,259),Vector2(146,252),
		Vector2(203,271),Vector2(268,298),Vector2(size.x,307)
	]),Color("#75def1",0.42),4,true)
	draw_polyline(PackedVector2Array([
		Vector2(169,-8),Vector2(175,53),Vector2(154,104),Vector2(176,160),
		Vector2(150,216),Vector2(147,252),Vector2(184,338),Vector2(174,size.y+8)
	]),Color("#233c3b",0.38),33,true)
	draw_polyline(PackedVector2Array([
		Vector2(169,-8),Vector2(175,53),Vector2(154,104),Vector2(176,160),
		Vector2(150,216),Vector2(147,252),Vector2(184,338),Vector2(174,size.y+8)
	]),edge,26,true)
	draw_polyline(PackedVector2Array([
		Vector2(169,-8),Vector2(175,53),Vector2(154,104),Vector2(176,160),
		Vector2(150,216),Vector2(147,252),Vector2(184,338),Vector2(174,size.y+8)
	]),Color("#fff0cb",0.39),3,true)
	# Little vegetation details appear naturally as the Garden develops.
	var flower_count := 5 + _total_levels
	for i in range(flower_count):
		var px := fposmod(17.0 + float(i)*61.7 + float(i % 3)*13.0,size.x - 22.0) + 9.0
		var py := fposmod(24.0 + float(i)*41.3 + float(i % 5)*17.0,size.y - 24.0) + 12.0
		if absf(px-162.0)<34.0:
			px = clampf(px+46.0,8.0,size.x-8.0)
		var tint := Color("#f6d77b") if i % 3 == 0 else (Color("#eaa9b6") if i % 3 == 1 else Color("#a3e9ad"))
		draw_circle(Vector2(px,py),2.4,tint)
		draw_circle(Vector2(px+1.4,py+1.6),1.0,Color("#fff6da"))
	# Tree belts / canopies are reserved away from tap zones and markers.
	var foliage := maxi(1,1+_total_levels / 6)
	for i in range(foliage):
		var pos := Vector2(8.0+float(i%2)*(size.x-16.0),40.0+float(i/2)*67.0)
		draw_circle(pos+Vector2(0,6),20,Color("#0b362f",0.45))
		draw_circle(pos,17,Color("#2d955d").lerp(Color("#79c76f"),maturity))
		draw_circle(pos+Vector2(6,-7),11,Color("#78bb69",0.68))
	draw_rect(bounds,Color("#000000",0.0),false,1)
