extends CanvasLayer

# A real, inspectable Rescue Garden built from owned Collection levels.
# The map is VIEW-ONLY. Players can inspect all six structures, including
# locked ones, then use the existing economy-checked Upgrades screen.
const UI = preload("res://scripts/ui/figma_reference_canvas.gd")
const WorldView = preload("res://scripts/ui/rescue_garden_world_view.gd")
const UpgradePreview = preload("res://scripts/ui/garden_upgrade_preview.gd")
const IDS := ["tree","bench","fountain","lanterns","cottage","rainbow_bridge"]
const TITLES := {
	"tree":"CANOPY TREE",
	"bench":"GARDEN BENCH",
	"fountain":"CRYSTAL FOUNTAIN",
	"lanterns":"LANTERN PATH",
	"cottage":"RESCUE COTTAGE",
	"rainbow_bridge":"RAINBOW BRIDGE"
}
const POSITIONS := {
	"tree":Vector2(4,42),
	"bench":Vector2(112,24),
	"fountain":Vector2(218,45),
	"lanterns":Vector2(4,220),
	"cottage":Vector2(112,200),
	"rainbow_bridge":Vector2(218,221)
}
const INK := Color("#f5f8fa")
const MUTED := Color("#cbd9e2")
const HIGHLIGHT := Color("#f5cb74")
var selected_id := "tree"
var _world: Control
var _stage_label: Label
var _detail_heading: Label
var _detail_level: Label
var _detail_effect: Label
var _detail_next: Label
var _landmark_buttons: Dictionary = {}
var _levels: Dictionary = {}

func _ready() -> void:
	layer = 155
	_refresh_owned_levels()
	var shade := ColorRect.new()
	shade.name = "RescueGardenShade"
	shade.color = Color("#071927",0.94)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var frame := Control.new()
	frame.name = "RescueGardenFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	var viewport_size := get_viewport().get_visible_rect().size
	var viewport_factor := minf(viewport_size.x / 390.0,viewport_size.y / 844.0)
	var scroll := ScrollContainer.new()
	scroll.name = "RescueGardenScroll"
	scroll.size = Vector2(356,750)
	scroll.custom_minimum_size = scroll.size
	scroll.scale = Vector2.ONE * viewport_factor
	scroll.position = (viewport_size - scroll.size * viewport_factor)*0.5
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	frame.add_child(scroll)

	var card := PanelContainer.new()
	card.name = "RescueGardenWorldCard"
	card.custom_minimum_size.x = 356
	card.add_theme_stylebox_override("panel",UI.solid_box(Color("#172b38"),20,Color("#78bda6"),2))
	scroll.add_child(card)
	var margin := MarginContainer.new()
	for edge in ["left","top","right","bottom"]:
		margin.add_theme_constant_override("margin_%s" % edge,14)
	card.add_child(margin)
	var stack := VBoxContainer.new()
	stack.name = "RescueGardenStack"
	stack.add_theme_constant_override("separation",8)
	margin.add_child(stack)

	_label(stack,"MY RESCUE GARDEN",23,INK,false)
	_stage_label = _label(stack,"",14,HIGHLIGHT,false)
	_stage_label.name = "RescueGardenStage"
	var intro := _label(stack,"Build a home for your rescued friends. Every permanent upgrade changes this garden and improves your rewards.",13,MUTED,true)
	intro.custom_minimum_size.y = 51

	var garden_holder := PanelContainer.new()
	garden_holder.name = "RescueGardenIllustration"
	garden_holder.custom_minimum_size = Vector2(326,360)
	garden_holder.add_theme_stylebox_override("panel",UI.solid_box(Color("#102f3d"),16,Color("#7dbea7"),1))
	stack.add_child(garden_holder)
	_world = WorldView.new()
	_world.name = "RescueGardenWorld"
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.custom_minimum_size = Vector2(326,360)
	garden_holder.add_child(_world)
	_world.size = Vector2(326,360)
	_world.configure(_levels)

	for id in IDS:
		_add_landmark_button(id)

	var detail := PanelContainer.new()
	detail.name = "RescueGardenDetail"
	detail.add_theme_stylebox_override("panel",UI.solid_box(Color("#233d4a"),14,Color("#557f87"),1))
	stack.add_child(detail)
	var detail_margin := MarginContainer.new()
	for edge in ["left","top","right","bottom"]:
		detail_margin.add_theme_constant_override("margin_%s" % edge,12)
	detail.add_child(detail_margin)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation",4)
	detail_margin.add_child(details)
	_detail_heading = _label(details,"",16,HIGHLIGHT,false)
	_detail_heading.name = "RescueGardenDetailHeading"
	_detail_level = _label(details,"",13,INK,false)
	_detail_level.name = "RescueGardenDetailLevel"
	_detail_effect = _label(details,"",13,Color("#9af0c7"),true)
	_detail_effect.name = "RescueGardenDetailEffect"
	_detail_next = _label(details,"",12,MUTED,true)
	_detail_next.name = "RescueGardenDetailNext"

	_button(stack,"UPGRADE MY GARDEN",Color("#276f55"),_show_upgrades)
	_button(stack,"BACK TO COLLECTION",Color("#395267"),queue_free)
	_select_landmark(selected_id)

func _refresh_owned_levels() -> void:
	_levels.clear()
	for id in IDS:
		_levels[id] = EconomyManager.collection_item_level(id)

func _label(parent: Node,value: String, font_size: int,tint: Color, wrap: bool) -> Label:
	var item := UI.label(value,font_size,tint,font_size >= 16)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.accessibility_name = value
	parent.add_child(item)
	return item

func _button(parent: Node,title: String,tint: Color,callback: Callable) -> Button:
	var item := UI.premium_button(title,15,INK,tint,14)
	item.custom_minimum_size = Vector2(320,48)
	item.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	item.focus_mode = Control.FOCUS_ALL
	item.accessibility_name = title
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.pressed.connect(callback)
	parent.add_child(item)
	item.set_deferred("focus_mode",Control.FOCUS_ALL)
	return item

func _add_landmark_button(id: String) -> void:
	var level := int(_levels.get(id,0))
	var button := Button.new()
	button.name = "GardenLandmark_%s" % id
	button.text = ""
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.accessibility_name = "%s, %s, tap to inspect" % [TITLES[id],"level %d of 5" % level if level>0 else "not yet built"]
	button.tooltip_text = button.accessibility_name
	button.position = POSITIONS[id]
	button.size = Vector2(103,124)
	button.custom_minimum_size = button.size
	button.pressed.connect(_select_landmark.bind(id))
	_world.add_child(button)
	_landmark_buttons[id] = button
	button.focus_mode = Control.FOCUS_ALL
	button.set_deferred("focus_mode",Control.FOCUS_ALL)

	var miniature := UpgradePreview.new()
	miniature.name = "GardenLandmarkArt_%s" % id
	miniature.position = Vector2(24,6)
	miniature.size = Vector2(55,70)
	miniature.mouse_filter = Control.MOUSE_FILTER_IGNORE
	miniature.configure(id,level)
	if level == 0:
		miniature.modulate.a = 0.56
	button.add_child(miniature)

	var name_label := UI.label(String(TITLES[id]).replace(" ","\n"),12,INK,true)
	name_label.name = "GardenLandmarkName_%s" % id
	name_label.position = Vector2(2,77)
	name_label.size = Vector2(99,30)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.accessibility_name = String(TITLES[id])
	button.add_child(name_label)
	var tier_label := UI.label("LV %d / 5" % level,12,HIGHLIGHT,true)
	tier_label.name = "GardenLandmarkLevel_%s" % id
	tier_label.position = Vector2(1,106)
	tier_label.size = Vector2(101,17)
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(tier_label)
	_style_landmark(button,id)

func _style_landmark(button: Button,id: String) -> void:
	var active := id == selected_id
	var unlocked := int(_levels.get(id,0)) > 0
	var fill := Color("#163742",0.94) if unlocked else Color("#263847",0.82)
	var edge := HIGHLIGHT if active else (Color("#73bd96",0.68) if unlocked else Color("#8b9ba7",0.48))
	var normal := UI.solid_box(fill,14,edge,2 if active else 1)
	button.add_theme_stylebox_override("normal",normal)
	button.add_theme_stylebox_override("hover",UI.solid_box(fill.lightened(0.11),14,HIGHLIGHT,2))
	button.add_theme_stylebox_override("pressed",UI.solid_box(fill.darkened(0.06),14,HIGHLIGHT,2))
	button.add_theme_stylebox_override("focus",UI.solid_box(Color("#000000",0),14,Color("#fff3af"),2))

func _select_landmark(id: String) -> void:
	if id not in IDS:
		return
	selected_id = id
	for other in IDS:
		var target := _landmark_buttons.get(other) as Button
		if target != null:
			_style_landmark(target,other)
	var level := int(_levels.get(id,0))
	var total := EconomyManager.collection_total_levels()
	var phase := "CLEARING" if total==0 else ("BUDDING" if total<6 else ("BLOOMING" if total<15 else ("THRIVING" if total<30 else "COMPLETE")))
	_stage_label.text = "%s • %d / 30 PERMANENT UPGRADES" % [phase,total]
	_stage_label.accessibility_name = _stage_label.text
	_detail_heading.text = TITLES[id]
	_detail_level.text = "LEVEL %d OF 5  •  %s" % [level,"NOT YET BUILT" if level == 0 else ("FULLY UPGRADED" if level == 5 else "BUILT")]
	_detail_effect.text = "TODAY: %s" % EconomyManager.collection_effect_text(id,level)
	_detail_next.text = "NEXT: %s" % EconomyManager.collection_effect_text(id,level+1) if level < 5 else "All five levels complete. Your permanent bonus remains active."
	for label in [_detail_heading,_detail_level,_detail_effect,_detail_next]:
		label.accessibility_name = label.text

func _show_upgrades() -> void:
	var parent := get_parent()
	queue_free()
	if parent != null and parent.has_method("build_collection_upgrades"):
		parent.call_deferred("build_collection_upgrades")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
