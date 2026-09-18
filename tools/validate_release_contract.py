from __future__ import annotations

from pathlib import Path

EXPECTED_PACKAGE = 'package/unique_name="com.eghosa.unjamgam"'
EXPECTED_VERSION_CODE = 'version/code=1'
EXPECTED_VERSION_NAME = 'version/name="1.0.0"'
EXPECTED_BACKEND_EXCLUSION = 'backend/*'
EXPECTED_UPLOAD_SECRET = 'secrets.UNJAM_ANDROID_UPLOAD_SHA1'

REQUIRED_RELEASE_TESTS = (
    'validate_campaign',
    'validate_campaign_diversity',
    'validate_level_launch',
    'validate_gameplay_interactions',
    'validate_progression_transitions',
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

    workflow = workflow_path.read_text(encoding='utf-8')
    preset = preset_path.read_text(encoding='utf-8')
    project = project_path.read_text(encoding='utf-8')

    errors: list[str] = []

    for token in (
        'default: 1',
        'default: 1.0.0',
        'EXPECTED_UPLOAD_SHA1',
        EXPECTED_UPLOAD_SECRET,
        '--export-release Android build/android/unjam-release.aab',
        'jarsigner -verify',
        'keytool -printcert -jarfile',
        'unzip -t',
        'sha256sum',
        'validate_purchase_claim_protocol.py',
        'backend/play-verifier',
        'npm test',
        'https://*/verify',
        'UNJAM_DEVELOPER_WEBSITE_URL',
        'check_live_monetization.py',
        '/readiness',
    ):
        if token not in workflow:
            errors.append(f'missing release workflow contract token: {token}')

    for test_name in REQUIRED_RELEASE_TESTS:
        if test_name not in workflow:
            errors.append(f'missing current release test: {test_name}')

    for test_name in OBSOLETE_RELEASE_TESTS:
        if test_name in workflow:
            errors.append(f'obsolete release test still referenced: {test_name}')

    for token in (
        EXPECTED_PACKAGE,
        EXPECTED_VERSION_CODE,
        EXPECTED_VERSION_NAME,
        EXPECTED_BACKEND_EXCLUSION,
        'permissions/internet=true',
        'permissions/access_network_state=true',
        'com.google.android.gms.permission.AD_ID',
    ):
        if token not in preset:
            errors.append(f'export preset does not preserve fresh-app/monetization contract: {token}')

    for token in (
        'res://addons/admob/plugin.cfg',
        'res://addons/GodotGooglePlayBilling/plugin.cfg',
        'ca-app-pub-7517898921176341~1892369383',
    ):
        if token not in project:
            errors.append(f'project.godot missing monetization contract token: {token}')

    if errors:
        print('Release contract validation failed:')
        for error in errors:
            print(f' - {error}')
        return 1

    print('Release contract validation passed.')
    print('Package: com.eghosa.unjamgam')
    print('Fresh-app default release: versionCode 1 / versionName 1.0.0')
    print('Upload certificate fingerprint is supplied at release time by UNJAM_ANDROID_UPLOAD_SHA1.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
