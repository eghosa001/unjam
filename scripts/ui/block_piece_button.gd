extends Button
class_name BlockPieceButton

var shape:Array=[]
var selected:=false
var used:=false
var accent:=Color("8b7cf6")
var hover:=0.0

func configure(value:Array,is_selected:bool,color:=Color("8b7cf6"))->void:
 shape=value.duplicate();selected=is_selected;used=shape.is_empty();accent=color;text="";flat=true;focus_mode=Control.FOCUS_NONE;disabled=used;mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;queue_redraw()
func _ready()->void:
 mouse_entered.connect(_hover.bind(true));mouse_exited.connect(_hover.bind(false));button_down.connect(func():scale=Vector2(0.96,0.96));button_up.connect(func():scale=Vector2.ONE)
func _hover(on:bool)->void:
 var t:=create_tween();t.tween_property(self,"hover",1.0 if on else 0.0,0.12);t.tween_callback(queue_redraw)
func _process(_d:float)->void:
 if hover>0.001 or selected:queue_redraw()
func _draw()->void:
 var r:=Rect2(Vector2(5,5),size-Vector2(10,10));_box(Rect2(r.position+Vector2(0,6),r.size),Color(0,0,0,0.25),22);_box(r,Color("17233d") if not selected else Color("342b68"),22)
 _border(r,Color("67e8cf") if selected else Color(0.7,0.74,1,0.18+hover*0.22),22,3 if selected else 2)
 if used:
  draw_string(ThemeDB.fallback_font,r.get_center()+Vector2(-24,6),"USED",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(0.55,0.59,0.68));return
 var mx:=0;var my:=0
 for p in shape:mx=maxi(mx,p.x);my=maxi(my,p.y)
 var block:=minf(34.0,minf((r.size.x-42.0)/float(mx+1),(r.size.y-34.0)/float(my+1)))
 var total:=Vector2((mx+1)*block,(my+1)*block);var origin:=r.get_center()-total*0.5
 for p in shape:
  var q:=Rect2(origin+Vector2(p.x,p.y)*block+Vector2(2,2),Vector2(block-4,block-4));_box(q,accent,7);draw_line(q.position+Vector2(5,5),Vector2(q.end.x-5,q.position.y+5),accent.lightened(0.3),2,true);draw_line(Vector2(q.position.x+5,q.end.y-5),q.end-Vector2(5,5),accent.darkened(0.25),2,true)
func _box(r:Rect2,c:Color,rad:int)->void:
 var s:=StyleBoxFlat.new();s.bg_color=c;s.corner_radius_top_left=rad;s.corner_radius_top_right=rad;s.corner_radius_bottom_left=rad;s.corner_radius_bottom_right=rad;draw_style_box(s,r)
func _border(r:Rect2,c:Color,rad:int,w:int)->void:
 var s:=StyleBoxFlat.new();s.bg_color=Color.TRANSPARENT;s.corner_radius_top_left=rad;s.corner_radius_top_right=rad;s.corner_radius_bottom_left=rad;s.corner_radius_bottom_right=rad;s.border_width_left=w;s.border_width_right=w;s.border_width_top=w;s.border_width_bottom=w;s.border_color=c;draw_style_box(s,r)
