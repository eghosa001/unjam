extends SceneTree

# Runs *after* the packaging asset generator. This proves Android icon
# safe-zone geometry and checks that the transparent logo is not stretched.
func _initialize() -> void:
	var errors: Array[String] = []
	var legacy := _image("res://assets/icon_user_512.png",Vector2i(512,512),errors)
	var foreground := _image("res://assets/icon_launcher_adaptive_432.png",Vector2i(432,432),errors)
	var system_splash := _image("res://assets/splash_emblem_safe_432.png",Vector2i(432,432),errors)
	var in_app := _image("res://assets/icon_user_adaptive_432.png",Vector2i(432,432),errors)
	var original := _image("res://store_assets/unjam_approved_logo_transparent.png",Vector2i.ZERO,errors)
	if foreground != null:
		_check_alpha_bounds(foreground,70,"Adaptive icon",errors)
	if system_splash != null:
		_check_alpha_bounds(system_splash,76,"Android 12 system splash",errors)
	if in_app != null and original != null:
		var source := original.get_used_rect()
		var actual := in_app.get_used_rect()
		var expected_aspect := float(source.size.x)/float(maxi(1,source.size.y))
		var actual_aspect := float(actual.size.x)/float(maxi(1,actual.size.y))
		if absf(expected_aspect-actual_aspect) > 0.03:
			errors.append("Startup logo is distorted: expected aspect %.3f, got %.3f" % [expected_aspect,actual_aspect])
		if actual.size.x > 355 or actual.size.y > 355:
			errors.append("Startup logo exceeds safely centered 354px bounds")
		_check_centered(actual,Vector2i(432,432),"In-app startup logo",errors)
	if legacy != null:
		for pixel in [Vector2i(0,0),Vector2i(511,0),Vector2i(0,511),Vector2i(511,511)]:
			if legacy.get_pixelv(pixel).a < 0.98:
				errors.append("Legacy launcher has transparent corner/black halo")
	if not errors.is_empty():
		for reason in errors:
			push_error(reason)
		quit(1)
		return
	print("ANDROID_BRAND_RASTERS_OK: Samsung masks, consistent U, undistorted in-app logo")
	quit(0)

func _image(path: String, size: Vector2i, errors: Array[String]) -> Image:
	var value := Image.load_from_file(path)
	if value == null or value.is_empty():
		errors.append("Could not load %s" % path)
		return null
	if size != Vector2i.ZERO and value.get_size() != size:
		errors.append("%s is %s instead of %s" % [path,str(value.get_size()),str(size)])
		return null
	return value

func _check_alpha_bounds(image: Image, margin: int, label: String, errors: Array[String]) -> void:
	var bounds := image.get_used_rect()
	var right := image.get_width() - (bounds.position.x+bounds.size.x)
	var bottom := image.get_height() - (bounds.position.y+bounds.size.y)
	if bounds.size.x == 0 or bounds.size.y == 0 or mini(mini(bounds.position.x,bounds.position.y),mini(right,bottom)) < margin:
		errors.append("%s not safely inside launcher mask: %s" % [label,str(bounds)])
	_check_centered(bounds,image.get_size(),label,errors)

func _check_centered(bounds: Rect2i, canvas: Vector2i, label: String, errors: Array[String]) -> void:
	var center := Vector2(bounds.position)+Vector2(bounds.size)*0.5
	if center.distance_to(Vector2(canvas)*0.5) > 9.0:
		errors.append("%s is off-center by %.1f pixels" % [label,center.distance_to(Vector2(canvas)*0.5)])
