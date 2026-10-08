extends SceneTree

const FakeProvider = preload("res://tests/fake_consent_provider.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var privacy := root.get_node_or_null("PrivacyManager")
	var save := root.get_node_or_null("SaveManager")
	var cloud := root.get_node_or_null("CloudSaveManager")
	if not _assert(privacy != null and save != null and cloud != null,"Required privacy, save or cloud autoload missing"):return
	var before: Dictionary = save.data.duplicate(true)
	var original_provider = privacy.provider
	var original_verified := bool(privacy.get("_session_consent_verified"))
	var original_test_mode: Variant = ProjectSettings.get_setting("monetization/admob_test_mode", false)
	ProjectSettings.set_setting("monetization/admob_test_mode",false)
	privacy.provider = null
	privacy.set("_session_consent_verified",false)
	save.data["privacy_consent_status"] = "obtained"
	if not _check(not privacy.may_request_ads(),"Persisted approval incorrectly authorized production ads",privacy,save,cloud,before,original_provider,original_verified,original_test_mode):return
	var provider := FakeProvider.new()
	root.add_child(provider)
	privacy.register_provider(provider)
	if not _check(not privacy.may_request_ads(),"A pending UMP callback must block ads",privacy,save,cloud,before,original_provider,original_verified,original_test_mode,provider):return
	provider.resolve("obtained")
	if not _check(privacy.may_request_ads(),"Current-session obtained consent should authorize ads",privacy,save,cloud,before,original_provider,original_verified,original_test_mode,provider):return
	# Even while a previous obtained status remains persisted, revalidation must
	# close the production gate until the provider resolves again.
	privacy.refresh_consent()
	if not _check(not privacy.may_request_ads(),"Refreshing consent left the gate open",privacy,save,cloud,before,original_provider,original_verified,original_test_mode,provider):return
	provider.resolve("required")
	if not _check(not privacy.may_request_ads(),"Required consent must block ads",privacy,save,cloud,before,original_provider,original_verified,original_test_mode,provider):return
	if not _check(not cloud.CLOUD_KEYS.has("privacy_consent_status") and not cloud._snapshot().has("privacy_consent_status"),"Cloud export includes device-local advertising consent",privacy,save,cloud,before,original_provider,original_verified,original_test_mode,provider):return
	var before_status := String(save.data.get("privacy_consent_status",""))
	var original_revision := int(save.data.get("cloud_save_revision",0))
	# Old remote records may still contain this key. Applying them must not
	# reactivate ads on a new device or overwrite local consent state.
	cloud.call("_apply_remote",{"privacy_consent_status":"not_required"},original_revision)
	if not _check(String(save.data.get("privacy_consent_status","")) == before_status and not privacy.may_request_ads(),"Legacy cloud backup changed local advertising authorization",privacy,save,cloud,before,original_provider,original_verified,original_test_mode,provider):return
	_cleanup(privacy,save,before,original_provider,original_verified,original_test_mode,provider)
	print("DEVICE_LOCAL_AD_CONSENT_OK: cached and remote consent cannot authorize ads without a current provider result.")
	quit(0)

func _check(ok: bool,reason: String,privacy: Node,save: Node,_cloud: Node,before: Dictionary,previous_provider: Node,verified: bool,mode: Variant,fixture: Node=null) -> bool:
	if ok:return true
	_cleanup(privacy,save,before,previous_provider,verified,mode,fixture)
	push_error(reason)
	quit(1)
	return false

func _cleanup(privacy: Node,save: Node,before: Dictionary,previous_provider: Node,verified: bool,mode: Variant,fixture: Node=null) -> void:
	privacy.provider = previous_provider
	privacy.set("_session_consent_verified",verified)
	ProjectSettings.set_setting("monetization/admob_test_mode",mode)
	save.data = before
	save.save()
	if fixture != null and is_instance_valid(fixture):
		fixture.queue_free()

func _assert(ok: bool,message: String) -> bool:
	if ok:return true
	push_error(message)
	quit(1)
	return false
