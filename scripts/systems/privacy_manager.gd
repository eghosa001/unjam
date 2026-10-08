extends Node

signal consent_state_changed(status: String)
signal privacy_options_requested
signal privacy_options_completed(status: String)

const VALID := ["unknown", "required", "obtained", "not_required"]
var provider: Node
# Cached consent is not authorization for ads on a new app session/device.
# UMP (or a provider's equivalent callback) must confirm the current state.
var _session_consent_verified := false

func _ready() -> void:
	var status := String(SaveManager.data.get("privacy_consent_status", "unknown"))
	if status not in VALID:
		status = "unknown"
	SaveManager.data.privacy_consent_status = status

func register_provider(value: Node) -> void:
	provider = value
	refresh_consent()

func refresh_consent() -> void:
	# Rechecking after resume/provider change temporarily closes the ad gate.
	# This avoids using stale cached approval while consent is unresolved.
	_session_consent_verified = false
	if provider != null and is_instance_valid(provider) and provider.has_method("request_consent"):
		provider.call("request_consent", Callable(self, "_set_status"))
	elif OS.get_name() != "Android":
		_set_status("not_required")
	else:
		_set_status("required")

func _set_status(status: String) -> void:
	if status not in VALID:
		status = "required"
	_session_consent_verified = status in ["obtained", "not_required"]
	SaveManager.data.privacy_consent_status = status
	SaveManager.save()
	consent_state_changed.emit(status)

func may_request_ads() -> bool:
	# Closed-test builds use Google's official demo ad units. Let those test ads
	# load even when UMP cannot resolve a consent message yet. Production builds
	# keep the strict consent gate because admob_test_mode is disabled there.
	if bool(ProjectSettings.get_setting("monetization/admob_test_mode", false)):
		return true
	return _session_consent_verified and String(SaveManager.data.get("privacy_consent_status", "unknown")) in ["obtained", "not_required"]

func show_privacy_options() -> void:
	privacy_options_requested.emit()
	if provider != null and is_instance_valid(provider) and provider.has_method("show_privacy_options"):
		provider.call("show_privacy_options", Callable(self, "_on_privacy_options_result"))
		return
	open_privacy_policy()
	privacy_options_completed.emit(String(SaveManager.data.get("privacy_consent_status", "unknown")))

func open_privacy_policy() -> void:
	var url := String(ProjectSettings.get_setting("monetization/privacy_policy_url", "")).strip_edges()
	if url.begins_with("https://"):
		OS.shell_open(url)

func _on_privacy_options_result(status: String) -> void:
	_set_status(status)
	privacy_options_completed.emit(String(SaveManager.data.get("privacy_consent_status", "required")))
