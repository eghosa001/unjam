@tool
extends EditorExportPlugin

var _replace_debug_aab := false
var _output_path := ""

func _get_name() -> String:
	return "UNJAMReleaseAABBuilder"

func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
	# This helper is CI-only and must never be packaged into the game.
	if path.begins_with("res://addons/release_aab_builder/"):
		skip()

func _export_begin(_features: PackedStringArray, is_debug: bool, path: String, _flags: int) -> void:
	_replace_debug_aab = false
	_output_path = ""
	if OS.get_environment("UNJAM_RELEASE_CHILD") == "1":
		return
	if is_debug and path.to_lower().ends_with(".aab"):
		_replace_debug_aab = true
		_output_path = path

func _export_end() -> void:
	if not _replace_debug_aab:
		return
	_replace_debug_aab = false
	var output_path := _output_path
	_output_path = ""
	if output_path.is_empty():
		return

	# The normal CI job has already generated an Android build template and a
	# temporary debug keystore. Re-use that temporary certificate only to let
	# Godot/Gradle create the genuine RELEASE variant. The resulting bundle is
	# re-signed with the permanent Play upload key after download.
	var debug_keystore := OS.get_environment("GODOT_ANDROID_KEYSTORE_DEBUG_PATH")
	var debug_user := OS.get_environment("GODOT_ANDROID_KEYSTORE_DEBUG_USER")
	var debug_password := OS.get_environment("GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD")
	if debug_keystore.is_empty() or debug_user.is_empty() or debug_password.is_empty():
		push_error("RELEASE_AAB_BUILD_ERROR: CI debug keystore environment is unavailable")
		DirAccess.remove_absolute(output_path)
		return

	OS.set_environment("GODOT_ANDROID_KEYSTORE_RELEASE_PATH", debug_keystore)
	OS.set_environment("GODOT_ANDROID_KEYSTORE_RELEASE_USER", debug_user)
	OS.set_environment("GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD", debug_password)
	OS.set_environment("UNJAM_RELEASE_CHILD", "1")

	# Remove the just-produced debug AAB first. If the release export fails,
	# the workflow's existing `test -s` guard will fail instead of uploading a
	# debug bundle by mistake.
	if FileAccess.file_exists(output_path):
		DirAccess.remove_absolute(output_path)

	var project_path := ProjectSettings.globalize_path("res://")
	var output: Array = []
	var args := PackedStringArray([
		"--headless",
		"--verbose",
		"--path", project_path,
		"--export-release", "Android", output_path
	])
	var exit_code := OS.execute(OS.get_executable_path(), args, output, true)
	for line in output:
		print(String(line))
	if exit_code != 0 or not FileAccess.file_exists(output_path):
		push_error("RELEASE_AAB_BUILD_ERROR: genuine Godot release export failed with code %d" % exit_code)
		if FileAccess.file_exists(output_path):
			DirAccess.remove_absolute(output_path)
		return
	print("RELEASE_AAB_BUILD_OK: replaced CI debug AAB artifact with genuine Godot --export-release output")
