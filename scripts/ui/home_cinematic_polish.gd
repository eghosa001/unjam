extends Node

var timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_apply")

func _process(delta: float) -> void:
	timer += delta
	if timer < 0.20:
		return
	timer = 0.0
	_apply()

func _apply() -> void:
	var home := get_parent().get_node_or_null("PremiumHome")
	if home == null or not home.visible:
		return
	var hero := home.find_child("HomeHero", true, false) as Control
	if hero != null:
		hero.custom_minimum_size = Vector2(0, 520)
		hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var art: Control = home.get("hero_art") as Control
	if art != null:
		art.custom_minimum_size = Vector2(390, 480)
		art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title: Label = home.get("hero_title") as Label
	if title != null:
		title.add_theme_font_size_override("font_size", 46)
	var subtitle: Label = home.get("hero_subtitle") as Label
	if subtitle != null:
		subtitle.add_theme_font_size_override("font_size", 21)
	var primary: Button = home.get("primary_button") as Button
	if primary != null:
		primary.custom_minimum_size.y = maxf(primary.custom_minimum_size.y, 92)
