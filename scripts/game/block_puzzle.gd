extends Control

signal finished(level_number: int)
signal quit_requested

const GAME_ID := "block_puzzle"
const GRID_SIZE := 8
const SHAPES := [
 [Vector2i(0,0)],[Vector2i(0,0),Vector2i(1,0)],[Vector2i(0,0),Vector2i(0,1)],[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2)],[Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)],[Vector2i(0,0),Vector2i(1,0),Vector2i(1,1)],[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(1,1)],[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)]]
var level_number:=1;var daily_mode:=false;var cells:Array=[];var cell_buttons:Array[BlockCellButton]=[];var pieces:Array=[];var selected_piece:=-1;var score:=0;var lines_cleared:=0;var placements:=0;var target_score:=80;var target_lines:=2;var par_placements:=18;var history:Array=[];var rng:=RandomNumberGenerator.new();var score_label:Label;var goal_label:Label;var status_label:Label;var hint_label:Label;var piece_row:HBoxContainer;var title_label:Label;var meta_label:Label;var completed:=false;var piece_batch:=0;var preview_origin:=Vector2i(-1,-1)
func _ready()->void:visible=true;mouse_filter=Control.MOUSE_FILTER_STOP;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);build_ui();load_level()
func difficulty()->String:return MultiGameManager.difficulty_for_level(level_number)
func level_config()->Dictionary:
 var world:=MultiGameManager.world_for_level(level_number);var d:=difficulty();var base:=55+mini(100,world*3);var lines:=1+int(world/12);var par:=20+int(world/15)
 match d:
  "easy":base=int(base*0.80);lines=maxi(1,lines-1);par+=5
  "hard":base=int(base*1.25);lines+=1
  "milestone":base=int(base*1.45);lines+=2
  "boss":base=int(base*1.70);lines+=3
 return {"target_score":base,"target_lines":mini(12,lines),"par":par}
func style_box(color:Color,radius:=22,border:=Color.TRANSPARENT,border_width:=0,shadow:=0)->StyleBoxFlat:
 var s:=StyleBoxFlat.new();s.bg_color=color;s.corner_radius_top_left=radius;s.corner_radius_top_right=radius;s.corner_radius_bottom_left=radius;s.corner_radius_bottom_right=radius
 if border_width>0:s.border_width_left=border_width;s.border_width_right=border_width;s.border_width_top=border_width;s.border_width_bottom=border_width;s.border_color=border
 if shadow>0:s.shadow_color=Color(0,0,0,0.28);s.shadow_size=shadow;s.shadow_offset=Vector2(0,6)
 return s
func style_button(button:Button,accent:=false)->void:
 var base:=Color("8b7cf6") if accent else Color("24355a");button.add_theme_stylebox_override("normal",style_box(Color(base,0.92),20,Color(1,1,1,0.09),1,6));button.add_theme_stylebox_override("hover",style_box(base.lightened(0.08),20,Color("c4b5fd"),2,8));button.add_theme_stylebox_override("pressed",style_box(base.darkened(0.12),20,Color.WHITE,2,2));button.add_theme_color_override("font_color",Color.WHITE);button.add_theme_font_size_override("font_size",20)
func build_ui()->void:
 var bg:=PremiumBackdrop.new();bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);bg.configure(Color("080d1d"),Color("8b7cf6"),MultiGameManager.world_for_level(level_number)-1);add_child(bg);PremiumVisuals.set_accent(Color("8b7cf6"))
 var outer:=MarginContainer.new();outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);for m in ["margin_left","margin_right"]:outer.add_theme_constant_override(m,34);outer.add_theme_constant_override("margin_top",40);outer.add_theme_constant_override("margin_bottom",38);add_child(outer);var root:=VBoxContainer.new();root.add_theme_constant_override("separation",11);outer.add_child(root)
 var header:=HBoxContainer.new();var back:=Button.new();back.text="←  BACK";back.custom_minimum_size=Vector2(145,66);style_button(back);back.pressed.connect(_quit);header.add_child(back);title_label=Label.new();title_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;title_label.add_theme_font_size_override("font_size",31);header.add_child(title_label);var retry:=Button.new();retry.text="RETRY";retry.custom_minimum_size=Vector2(135,66);style_button(retry);retry.pressed.connect(restart_level);header.add_child(retry);root.add_child(header)
 meta_label=Label.new();meta_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;meta_label.add_theme_font_size_override("font_size",17);meta_label.add_theme_color_override("font_color",Color("a7b0cb"));root.add_child(meta_label);score_label=Label.new();score_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;score_label.add_theme_font_size_override("font_size",22);root.add_child(score_label);goal_label=Label.new();goal_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;goal_label.add_theme_color_override("font_color",Color("67e8cf"));root.add_child(goal_label)
 var center:=CenterContainer.new();center.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(center);var grid:=GridContainer.new();grid.columns=GRID_SIZE;grid.add_theme_constant_override("h_separation",5);grid.add_theme_constant_override("v_separation",5);center.add_child(grid)
 for y in range(GRID_SIZE):
  for x in range(GRID_SIZE):
   var b:=BlockCellButton.new();b.custom_minimum_size=Vector2(105,105);b.configure(false,false,Color("8b7cf6"),y*GRID_SIZE+x);b.mouse_entered.connect(_preview_at.bind(Vector2i(x,y)));b.pressed.connect(place_selected.bind(Vector2i(x,y)));grid.add_child(b);cell_buttons.append(b)
 var pt:=Label.new();pt.text="CHOOSE A PIECE";pt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;root.add_child(pt);piece_row=HBoxContainer.new();piece_row.alignment=BoxContainer.ALIGNMENT_CENTER;piece_row.add_theme_constant_override("separation",12);root.add_child(piece_row)
 var actions:=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_CENTER;actions.add_theme_constant_override("separation",16);var undo:=Button.new();undo.text="↶  UNDO";undo.custom_minimum_size=Vector2(250,70);style_button(undo);undo.pressed.connect(undo_move);actions.add_child(undo);var hint:=Button.new();hint.text="✦  HINT";hint.custom_minimum_size=Vector2(250,70);style_button(hint,true);hint.pressed.connect(show_hint);actions.add_child(hint);root.add_child(actions);hint_label=Label.new();hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;root.add_child(hint_label);status_label=Label.new();status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;status_label.add_theme_font_size_override("font_size",21);status_label.add_theme_color_override("font_color",Color("67e8cf"));root.add_child(status_label);PremiumVisuals.entrance(root,0.02)
func load_level()->void:
 completed=false;selected_piece=-1;preview_origin=Vector2i(-1,-1);score=0;lines_cleared=0;placements=0;piece_batch=0;history.clear();status_label.text="";hint_label.text="Select a shape, then place it on the grid";var c:=level_config();target_score=int(c.target_score);target_lines=int(c.target_lines);par_placements=int(c.par);title_label.text="DAILY BLOCK PUZZLE" if daily_mode else "BLOCK PUZZLE  •  LEVEL %04d"%level_number;meta_label.text="%s  •  %s  •  WORLD %d"%[difficulty().to_upper(),MultiGameManager.world_name(GAME_ID,MultiGameManager.world_for_level(level_number)).to_upper(),MultiGameManager.world_for_level(level_number)];rng.seed=level_number*104729+(1 if daily_mode else 0);cells.clear();for _y in range(GRID_SIZE):cells.append([false,false,false,false,false,false,false,false]);refill_pieces();_restore_checkpoint();render();AnalyticsManager.track("block_puzzle_level_started",{"level":level_number,"difficulty":difficulty(),"daily":daily_mode})
func refill_pieces()->void:
 pieces.clear();piece_batch+=1
 for _i in range(3):
  var max_shape:=SHAPES.size()-1;if difficulty()=="easy":max_shape=5;elif difficulty()=="medium":max_shape=7;pieces.append(SHAPES[rng.randi_range(0,max_shape)].duplicate())
 selected_piece=-1
 if not any_move_available():pieces[0]=SHAPES[0].duplicate()
func render()->void:
 for y in range(GRID_SIZE):
  for x in range(GRID_SIZE):
   var preview:=false
   if selected_piece>=0 and preview_origin.x>=0:
    for p in pieces[selected_piece]:
     if preview_origin+Vector2i(p.x,p.y)==Vector2i(x,y):preview=true
   cell_buttons[y*GRID_SIZE+x].configure(bool(cells[y][x]),preview and can_place(pieces[selected_piece],preview_origin),Color("8b7cf6"),y*GRID_SIZE+x)
 score_label.text="SCORE  %d / %d    •    LINES  %d / %d"%[score,target_score,lines_cleared,target_lines];goal_label.text="PLACEMENTS  %d    •    PERFECT ≤ %d"%[placements,par_placements];render_pieces()
func render_pieces()->void:
 for child in piece_row.get_children():child.queue_free()
 for i in range(pieces.size()):var b:=BlockPieceButton.new();b.custom_minimum_size=Vector2(285,130);b.configure(pieces[i],i==selected_piece,Color("8b7cf6"));b.pressed.connect(select_piece.bind(i));piece_row.add_child(b)
func _preview_at(origin:Vector2i)->void:
 if selected_piece<0:return
 preview_origin=origin;render()
func select_piece(index:int)->void:
 if completed or pieces[index].is_empty():return
 selected_piece=index;preview_origin=Vector2i(-1,-1);status_label.text="Piece %d selected"%(index+1);hint_label.text="Hover or tap a grid cell to preview and place";render()
func place_selected(origin:Vector2i)->void:
 if completed:return
 if selected_piece<0 or selected_piece>=pieces.size():status_label.text="Choose a piece first";return
 var shape:Array=pieces[selected_piece]
 if not can_place(shape,origin):status_label.text="That shape does not fit there";PremiumVisuals.screen_flash(Color("ff6b7a"),0.045);return
 history.append({"cells":cells.duplicate(true),"pieces":pieces.duplicate(true),"selected":selected_piece,"score":score,"lines":lines_cleared,"placements":placements,"batch":piece_batch,"rng_state":rng.state});for p in shape:cells[origin.y+p.y][origin.x+p.x]=true
 score+=shape.size();placements+=1;pieces[selected_piece]=[];selected_piece=-1;preview_origin=Vector2i(-1,-1);var cleared:=clear_lines()
 if cleared>0:lines_cleared+=cleared;score+=cleared*20;status_label.text="%d LINE%s CLEARED  •  COMBO +%d"%[cleared,"S" if cleared!=1 else "",cleared*20];PremiumVisuals.burst(Vector2(540,840),Color("8b7cf6"),10+cleared*4)
 else:status_label.text="Placed"
 if reached_goal():render();complete_level();return
 if all_pieces_used():refill_pieces()
 render();_save_checkpoint();if not any_move_available():status_label.text="NO MOVES — UNDO, HINT OR RETRY"
func can_place(shape:Array,origin:Vector2i)->bool:
 for p in shape:
  var x:=origin.x+p.x;var y:=origin.y+p.y
  if x<0 or x>=GRID_SIZE or y<0 or y>=GRID_SIZE or bool(cells[y][x]):return false
 return true
func clear_lines()->int:
 var rows:Array[int]=[];var cols:Array[int]=[]
 for y in range(GRID_SIZE):var full:=true;for x in range(GRID_SIZE):if not bool(cells[y][x]):full=false;break;if full:rows.append(y)
 for x in range(GRID_SIZE):var full:=true;for y in range(GRID_SIZE):if not bool(cells[y][x]):full=false;break;if full:cols.append(x)
 for y in rows:for x in range(GRID_SIZE):cells[y][x]=false
 for x in cols:for y in range(GRID_SIZE):cells[y][x]=false
 return rows.size()+cols.size()
func reached_goal()->bool:return score>=target_score and lines_cleared>=target_lines
func all_pieces_used()->bool:
 for s in pieces:if not s.is_empty():return false
 return true
func any_move_available()->bool:
 for s in pieces:
  if s.is_empty():continue
  for y in range(GRID_SIZE):for x in range(GRID_SIZE):if can_place(s,Vector2i(x,y)):return true
 return false
func undo_move()->void:
 if history.is_empty() or completed:status_label.text="Nothing to undo";return
 var s:Dictionary=history.pop_back();cells=s.cells.duplicate(true);pieces=s.pieces.duplicate(true);selected_piece=int(s.selected);score=int(s.score);lines_cleared=int(s.lines);placements=int(s.placements);piece_batch=int(s.batch);rng.state=int(s.rng_state);preview_origin=Vector2i(-1,-1);SaveManager.record_undo();status_label.text="Move undone";render();_save_checkpoint()
func show_hint()->void:
 if completed:return
 for pi in range(pieces.size()):
  if pieces[pi].is_empty():continue
  for y in range(GRID_SIZE):for x in range(GRID_SIZE):if can_place(pieces[pi],Vector2i(x,y)):selected_piece=pi;preview_origin=Vector2i(x,y);hint_label.text="Try piece %d at row %d, column %d"%[pi+1,y+1,x+1];SaveManager.record_hint();render();return
 hint_label.text="No placement found — undo or retry"
func complete_level()->void:
 if completed:return
 completed=true;MultiGameManager.clear_checkpoint(GAME_ID);var stars:=3 if placements<=par_placements else (2 if placements<=par_placements+6 else 1);if daily_mode:MultiGameManager.complete_daily(GAME_ID,100+stars*25);else:MultiGameManager.complete_level(GAME_ID,level_number,stars,30);status_label.text="LEVEL COMPLETE  •  %d ★"%stars;PremiumVisuals.burst(Vector2(540,850),Color("8b7cf6"),26);AnalyticsManager.track("block_puzzle_completed",{"level":level_number,"score":score,"lines":lines_cleared,"placements":placements,"stars":stars,"daily":daily_mode});await get_tree().create_timer(0.9).timeout;finished.emit(-1 if daily_mode else level_number)
func restart_level()->void:MultiGameManager.clear_checkpoint(GAME_ID);load_level()
func _save_checkpoint()->void:
 if completed:return
 MultiGameManager.save_checkpoint(GAME_ID,{"level":level_number,"daily":daily_mode,"cells":cells.duplicate(true),"pieces":pieces.duplicate(true),"selected":selected_piece,"score":score,"lines":lines_cleared,"placements":placements,"batch":piece_batch,"rng_state":rng.state,"history":history.duplicate(true)})
func _restore_checkpoint()->void:
 var c:=MultiGameManager.checkpoint(GAME_ID)
 if c.is_empty() or int(c.get("level",-1))!=level_number or bool(c.get("daily",false))!=daily_mode:return
 var sc=c.get("cells",[])
 if sc is Array and sc.size()==GRID_SIZE:cells=sc.duplicate(true);var sp=c.get("pieces",[]);if sp is Array:pieces=sp.duplicate(true);selected_piece=int(c.get("selected",-1));score=maxi(0,int(c.get("score",0)));lines_cleared=maxi(0,int(c.get("lines",0)));placements=maxi(0,int(c.get("placements",0));piece_batch=maxi(0,int(c.get("batch",0)));rng.state=int(c.get("rng_state",rng.state));var sh=c.get("history",[]);if sh is Array:history=sh.duplicate(true)
func _quit()->void:_save_checkpoint();quit_requested.emit()
