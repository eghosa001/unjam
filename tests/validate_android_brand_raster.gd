extends SceneTree

# Runs *after* the packaging asset generator. This proves Android icon
# safe-zone geometry and checks that the transparent logo is not stretched.
func _initialize() -> void:
	# Selective Godot CI inspects the repository's committed icons; they are
	# intentionally not regenerated on that path. The branded-artifact preview
	# workflow sets this flag after rebuilding the rasters and runs this test
	# against the actual APK inputs.
	if OS.get_environment("UNJAM_ANDROID_BRAND_RASTER_READY") != "1":
		print("BRAND_RASTER_CHECK_DEFERRED_TO_GENERATED_ASSET_WORKFLOW")
		quit(0)
		return
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
	# The previous U-only launch icon passed margin tests. Reject that
	# regression by comparing each generated mask to the actual approved
	# coloured logo image (including the lettered UNJAM wordmark).
	if original != null:
		for pair in [[foreground,"Adaptive launcher"],[system_splash,"System splash"],[in_app,"In-app boot"]]:
			if pair[0] != null:
				_check_matches_official(pair[0] as Image, original, String(pair[1]),errors)
		if legacy != null:
			_check_multicolour_legacy(legacy,errors)
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
	print("ANDROID_APPROVED_LOGO_ALL_LAUNCH_SURFACES_OK")
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

# Compare the artwork itself, not its filename, dimensions or margin alone.
func _check_matches_official(image: Image, source: Image, label: String, errors: Array[String]) -> void:
	var source_bounds := source.get_used_rect()
	var generated_bounds := image.get_used_rect()
	if source_bounds.size.x < 1 or generated_bounds.size.x < 1:
		errors.append("%s does not contain source artwork" % label)
		return
	var original_ratio := float(source_bounds.size.x)/float(source_bounds.size.y)
	var generated_ratio := float(generated_bounds.size.x)/float(generated_bounds.size.y)
	if absf(original_ratio-generated_ratio) > 0.03:
		errors.append("%s artwork stretched or cropped (ratio %.2f, expected %.2f)" % [label,generated_ratio,original_ratio])
		return
	var src := source.get_region(source_bounds)
	var dst := image.get_region(generated_bounds)
	src.resize(64,64,Image.INTERPOLATE_LANCZOS)
	dst.resize(64,64,Image.INTERPOLATE_LANCZOS)
	var mismatch := 0.0
	for y in range(64):
		for x in range(64):
			var p := src.get_pixel(x,y)
			var q := dst.get_pixel(x,y)
			mismatch += (absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)+absf(p.a-q.a))*0.25
	var mean_error := mismatch/4096.0
	if mean_error > 0.09:
		errors.append("%s differs from approved launch logo (mean error %.3f)" % [label,mean_error])

func _check_multicolour_legacy(image: Image, errors: Array[String]) -> void:
	var red_count := 0
	var green_count := 0
	for y in range(0,image.get_height(),4):
		for x in range(0,image.get_width(),4):
			var p := image.get_pixel(x,y)
			if p.r > 0.68 and p.g < 0.44 and p.b < 0.62:
				red_count += 1
			if p.g > 0.53 and p.r < 0.45 and p.b < 0.64:
				green_count += 1
	if red_count < 4 or green_count < 4:
		errors.append("Legacy icon is still the generic yellow U, not the approved full-colour logo")
