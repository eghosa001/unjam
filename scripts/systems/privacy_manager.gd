extends Node

signal consent_state_changed(status: String)
signal privacy_options_requested

const VALID := ["unknown", "required", "obtained", "not_required"]
var provider: Node

func _ready() -> void:
	var status := String(SaveManager.data.get("privacy_consent_status", "unknown"))
	if status not in VALID:
		status = "unknown"
	SaveManager.data.privacy_consent_status = status

func register_provider(value: Node) -> void:
	provider = value
	refresh_consent()

func refresh_consent() -> void:
	if provider != null and is_instance_valid(provider) and provider.has_method("request_consent"):
		provider.call("request_consent", Callable(self, "_set_status"))
	elif OS.get_name() != "Android":
		_set_status("not_required")
	else:
		_set_status("required")

func _set_status(status: String) -> void:
	if status not in VALID:
		status = "required"
	SaveManager.data.privacy_consent_status = status
	SaveManager.save()
	consent_state_changed.emit(status)

func may_request_ads() -> bool:
	return String(SaveManager.data.get("privacy_consent_status", "unknown")) in ["obtained", "not_required"]

func show_privacy_options() -> void:
	privacy_options_requested.emit()
	if provider != null and is_instance_valid(provider) and provider.has_method("show_privacy_options"):
		provider.call("show_privacy_options", Callable(self, "_set_status"))
		return
	var url := String(ProjectSettings.get_setting("monetization/privacy_policy_url", ""))
	if not url.is_empty():
		OS.shell_open(url)
