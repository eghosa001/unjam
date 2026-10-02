from __future__ import annotations

import ast
import re
from pathlib import Path

EXPECTED_PACKAGE = 'package/unique_name="com.eghosa.unjamgam"'
EXPECTED_BACKEND_EXCLUSION = 'supabase/*'
EXPECTED_UPLOAD_SECRET = 'secrets.UNJAM_ANDROID_UPLOAD_SHA1'

REQUIRED_RELEASE_TESTS = (
    'validate_campaign',
    'validate_campaign_diversity',
    'validate_level_launch',
    'validate_gameplay_interactions',
    'validate_progression_transitions',
    'validate_theme_integrity',
    'validate_decorative_3d_frame_budget',
    'validate_water_constructive_solvability',
)

OBSOLETE_RELEASE_TESTS = (
    'validate_levels',
    'validate_first_100_progression',
    'validate_first_200_playability',
    'validate_campaign_1000',
)


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    workflow_path = root / '.github' / 'workflows' / 'android-release.yml'
    preset_path = root / 'export_presets.cfg'
    project_path = root / 'project.godot'
    live_checker_path = root / 'tools' / 'check_live_monetization.py'
    icon_path = root / 'assets' / 'icon_user_512.png'
    canonical_icon_path = root / 'store_assets' / 'unjam_google_play_icon_512.png'
    adaptive_bg_path = root / 'assets' / 'icon_adaptive_background.svg'
    adaptive_fg_path = root / 'assets' / 'icon_launcher_adaptive_432.png'
    splash_fg_path = root / 'assets' / 'splash_emblem_safe_432.png'
    startup_logo_path = root / 'assets' / 'unjam_startup_logo.png'
    boot_scene_path = root / 'scenes' / 'Boot.tscn'
    boot_script_path = root / 'scripts' / 'ui' / 'boot_splash.gd'
    brand_prep_path = root / 'tools' / 'prepare_android_brand_assets.gd'
    robust_main_path = root / 'scripts' / 'ui' / 'robust_main.gd'
    feedback_path = root / 'scripts' / 'systems' / 'feedback_manager.gd'
    selected_music_path = root / 'assets' / 'audio' / 'unjam_happy_lullaby.ogg'
    selected_music_license_path = root / 'assets' / 'audio' / 'UNJAM_HAPPY_LULLABY_LICENSE.txt'
    cloud_save_path = root / 'scripts' / 'systems' / 'cloud_save_manager.gd'
    cloud_edge_path = root / 'supabase' / 'functions' / 'unjam-cloud-save' / 'index.ts'
    cloud_migration_path = root / 'supabase' / 'migrations' / '20261001_create_player_cloud_saves.sql'

    workflow = workflow_path.read_text(encoding='utf-8')
    preset = preset_path.read_text(encoding='utf-8')
    project = project_path.read_text(encoding='utf-8')
    live_checker = live_checker_path.read_text(encoding='utf-8')
    adaptive_bg = adaptive_bg_path.read_text(encoding='utf-8')
    brand_prep = brand_prep_path.read_text(encoding='utf-8')
    robust_main = robust_main_path.read_text(encoding='utf-8')
    boot_scene = boot_scene_path.read_text(encoding='utf-8')
    boot_script = boot_script_path.read_text(encoding='utf-8')
    feedback = feedback_path.read_text(encoding='utf-8')
    selected_music_license = selected_music_license_path.read_text(encoding='utf-8') if selected_music_license_path.exists() else ''
    cloud_save = cloud_save_path.read_text(encoding='utf-8') if cloud_save_path.exists() else ''
    cloud_edge = cloud_edge_path.read_text(encoding='utf-8') if cloud_edge_path.exists() else ''
    cloud_migration = cloud_migration_path.read_text(encoding='utf-8') if cloud_migration_path.exists() else ''

    errors: list[str] = []

    try:
        ast.parse(live_checker, filename=str(live_checker_path))
    except SyntaxError as exc:
        errors.append(f'live monetization checker has invalid Python syntax: {exc.msg} at line {exc.lineno}')

    for token in (
        'EXPECTED_UPLOAD_SHA1',
        EXPECTED_UPLOAD_SECRET,
        '--export-release Android build/android/unjam-release.aab',
        'jarsigner -verify',
        'keytool -printcert -jarfile',
        'unzip -t',
        'sha256sum',
        'validate_purchase_claim_protocol.py',
        'Validate Supabase purchase backend contract',
        'UNJAM_DEVELOPER_WEBSITE_URL',
        'check_live_monetization.py',
        "targetSdkVersion:'36'",
        "native-code: 'arm64-v8a'",
        '16 KB native page compatibility',
        'Refuse unsigned release artifact',
        'grep -F "jar verified." build/android/jarsigner-verify.log',
        'prepare_android_brand_assets.gd',
        'AAB_FOREGROUND_BYTES',
        'test "$AAB_FOREGROUND_BYTES" -gt 1000',
    ):
        if token not in workflow:
            errors.append(f'missing release workflow contract token: {token}')

    for test_name in REQUIRED_RELEASE_TESTS:
        if test_name not in workflow:
            errors.append(f'missing current release test: {test_name}')

    for test_name in OBSOLETE_RELEASE_TESTS:
        if test_name in workflow:
            errors.append(f'obsolete release test still referenced: {test_name}')

    version_code_match = re.search(r'^version/code=(\d+)$', preset, re.MULTILINE)
    if version_code_match is None or int(version_code_match.group(1)) < 1:
        errors.append('export preset must define a positive Android version/code')

    version_name_match = re.search(r'^version/name="([^"]+)"$', preset, re.MULTILINE)
    if version_name_match is None or not version_name_match.group(1).strip():
        errors.append('export preset must define a non-empty Android version/name')

    for token in (
        EXPECTED_PACKAGE,
        EXPECTED_BACKEND_EXCLUSION,
        'package/signed=true',
        'gradle_build/export_format=1',
        'gradle_build/target_sdk="36"',
        'architectures/arm64-v8a=true',
        'architectures/armeabi-v7a=false',
        'architectures/x86=false',
        'architectures/x86_64=false',
        'permissions/internet=true',
        'permissions/access_network_state=true',
        'com.google.android.gms.permission.AD_ID',
        'user_data_backup/allow=true',
    ):
        if token not in preset:
            errors.append(f'export preset does not preserve fresh-app/monetization contract: {token}')

    for token in (
        'supabase_url="https://sotwqajpcyjlpxntjddr.supabase.co"',
        'supabase_publishable_key="sb_publishable_',
        'res://addons/admob/plugin.cfg',
        'res://addons/GodotGooglePlayBilling/plugin.cfg',
        'ca-app-pub-7517898921176341~1892369383',
        'privacy_policy_url="https://unjam-site-prod-production.up.railway.app/privacy.html"',
        'developer_website_url="https://unjam-site-prod-production.up.railway.app"',
        'CloudSaveManager="*res://scripts/systems/cloud_save_manager.gd"',
    ):
        if token not in project:
            errors.append(f'project.godot missing monetization contract token: {token}')

    for token in (
        'unjam-purchase',
        'google_play',
        'postgres',
        'voided_purchases',
        'server_finalization',
        'voided_purchase_sync',
        'install_bound_revocations',
        'database_rate_limit',
        'product_catalog',
        'product_catalog_validation',
        'UNJAM_SUPABASE_URL',
    ):
        if token not in live_checker:
            errors.append(f'live monetization checker missing dependency contract token: {token}')

    lifecycle_migration = root / 'supabase' / 'migrations' / '20260922_harden_monetization_lifecycle.sql'
    if not lifecycle_migration.exists():
        errors.append('hardened monetization lifecycle migration is missing')
    else:
        lifecycle_text = lifecycle_migration.read_text(encoding='utf-8')
        for token in (
            'play_purchase_installations',
            'play_request_limits',
            'play_voided_sync_state',
            'mark_play_purchase_voided',
            'get_play_install_revocations',
            'consume_play_request_slot',
        ):
            if token not in lifecycle_text:
                errors.append(f'hardened monetization lifecycle migration missing token: {token}')

    if not icon_path.exists() or not canonical_icon_path.exists():
        errors.append('approved 512x512 full UNJAM launcher artwork is missing')
    elif icon_path.read_bytes() != canonical_icon_path.read_bytes():
        errors.append('packaged launcher source must exactly match the approved full UNJAM artwork')
    if not adaptive_fg_path.exists():
        errors.append('former 432x432 UNJAM adaptive launcher foreground is missing')
    if not brand_prep_path.exists():
        errors.append('Android brand raster preparation script is missing')
    if 'viewBox="0 0 432 432"' not in adaptive_bg:
        errors.append('adaptive icon background must remain a 432x432 Android layer')
    if not splash_fg_path.exists():
        errors.append('safe 432x432 Android system-splash emblem is missing')
    if not startup_logo_path.exists():
        errors.append('exported full startup logo is missing')
    for token in ('#173BFF', '#0B66DB', '#24106F'):
        if token not in adaptive_bg:
            errors.append(f'adaptive launcher background is missing former blend color: {token}')
    for token in (
        'SOURCE := "res://store_assets/unjam_google_play_icon_512.png"',
        'ADAPTIVE_OUT := "res://assets/icon_launcher_adaptive_432.png"',
        'SPLASH_SOURCE := "res://store_assets/unjam_approved_logo_transparent.png"',
        'SYSTEM_SPLASH_OUT := "res://assets/splash_emblem_safe_432.png"',
        'LEGACY_CONTENT := 512',
        'ADAPTIVE_CONTENT := 344',
        'SYSTEM_SPLASH_CONTENT := 280',
        'SPLASH_SIZE := 432',
        'Image.INTERPOLATE_LANCZOS',
    ):
        if token not in brand_prep:
            errors.append(f'Former Android launcher preparation missing token: {token}')
    for token in (
        'HOLD_SECONDS := 1.55',
        'FADE_SECONDS := 0.25',
        'MAIN_SCENE := "res://scenes/Main.tscn"',
        'func _open_main() -> void:',
        'get_tree().change_scene_to_file(MAIN_SCENE)',
    ):
        if token not in boot_script:
            errors.append(f'standalone Boot behavior missing token: {token}')
    for token in (
        'path="res://assets/unjam_startup_logo.png"',
        'custom_minimum_size = Vector2(560, 560)',
    ):
        if token not in boot_scene:
            errors.append(f'standalone Boot scene missing token: {token}')

    for retired in ('BrandedLaunch', 'StartupBrandHold', '_show_startup_brand_hold', '_fade_startup_brand_hold', 'STARTUP_BRAND_TEXTURE'):
        if retired in robust_main:
            errors.append(f'interactive Main must not own startup overlay: {retired}')

    if not selected_music_path.exists() or selected_music_path.stat().st_size < 100_000:
        errors.append('selected Happy Lullaby music asset is missing or unexpectedly small')
    for token in (
        'HAPPY_LULLABY_PATH := "res://assets/audio/unjam_happy_lullaby.ogg"',
        'MUSIC_VOLUME_DB := -7.0',
        'MUSIC_FADE_IN_SECONDS := 0.90',
        'selected_track.loop = true',
        'if music_player.stream != music_stream:',
        'call_deferred("_prewarm_common_sfx")',
        'func _prewarm_common_sfx() -> void:',
    ):
        if token not in feedback:
            errors.append(f'selected music playback contract missing token: {token}')
    for token in ('Happy Lullaby (song17)', 'cynicmusic', 'The Cynic Project', 'CC0', 'opengameart.org/content/happy-lullaby-song17'):
        if token not in selected_music_license:
            errors.append(f'selected music provenance missing token: {token}')

    if 'run/main_scene="res://scenes/Boot.tscn"' not in project:
        errors.append('project must boot through the standalone splash scene')
    if 'config/icon="res://assets/icon_user_512.png"' not in project:
        errors.append('project launcher icon is not wired to the approved full UNJAM logo')

    for token in (
        'boot_splash/show_image=false',
        'boot_splash/image="res://assets/splash_emblem_safe_432.png"',
        'boot_splash/bg_color=Color(0.062745, 0.152941, 0.415686, 1)',
        'environment/defaults/default_clear_color=Color(0.062745, 0.152941, 0.415686, 1)',
    ):
        if token not in project:
            errors.append(f'project startup handoff does not preserve the seamless approved-logo contract: {token}')

    for token in (
        'launcher_icons/main_192x192="res://assets/icon_user_512.png"',
        'launcher_icons/adaptive_foreground_432x432="res://assets/icon_launcher_adaptive_432.png"',
        'launcher_icons/adaptive_background_432x432="res://assets/icon_adaptive_background.svg"',
        'splash_screen/icon="res://assets/splash_emblem_safe_432.png"',
        'splash_screen/background_color=Color(0.062745, 0.152941, 0.415686, 1)',
        'splash_screen/disable_godot_boot_splash=true',
    ):
        if token not in preset:
            errors.append(f'Android launcher/splash assets are not wired to the restored-launcher contract: {token}')

    for token in (
        'FUNCTION_NAME := "unjam-cloud-save"',
        'CLOUD_ID_BYTES := 32',
        'generate_random_bytes(CLOUD_ID_BYTES).hex_encode()',
        'SaveManager.save_committed.connect(_on_save_committed)',
        '"action": "pull"',
        '"action": "push"',
        '"base_revision"',
    ):
        if token not in cloud_save:
            errors.append(f'cloud save client missing token: {token}')
    for token in (
        'ALLOWED_KEYS',
        'SUPABASE_SERVICE_ROLE_KEY',
        'sha256Hex(cloudId)',
        'MAX_PAYLOAD_BYTES',
        'conflict: true',
    ):
        if token not in cloud_edge:
            errors.append(f'cloud save edge function missing token: {token}')
    for token in (
        'player_cloud_saves',
        'enable row level security',
        'revoke all on table public.player_cloud_saves from anon, authenticated',
    ):
        if token not in cloud_migration:
            errors.append(f'cloud save migration missing token: {token}')

    if errors:
        print('Release contract validation failed:')
        for error in errors:
            print(f' - {error}')
        return 1

    print('Release contract validation passed.')
    print('Package: com.eghosa.unjamgam')
    print(
        f'Android release metadata: versionCode {version_code_match.group(1)} / '
        f'versionName {version_name_match.group(1)}'
    )
    print('Upload certificate fingerprint is supplied at release time by UNJAM_ANDROID_UPLOAD_SHA1.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
