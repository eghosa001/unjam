from __future__ import annotations

from pathlib import Path

EXPECTED_PACKAGE = 'package/unique_name="com.eghosa.unjam"'
EXPECTED_VERSION_CODE = 'version/code=2'
EXPECTED_VERSION_NAME = 'version/name="1.0.1"'
EXPECTED_UPLOAD_SHA1 = '8C:B6:B3:07:8E:AB:45:31:A3:03:D6:36:FA:05:C8:E6:4D:6E:7A:B9'

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

    workflow = workflow_path.read_text(encoding='utf-8')
    preset = preset_path.read_text(encoding='utf-8')

    errors: list[str] = []

    for token in (
        'default: 2',
        'EXPECTED_UPLOAD_SHA1',
        EXPECTED_UPLOAD_SHA1,
        '--export-release Android build/android/unjam-release.aab',
        'jarsigner -verify',
        'keytool -printcert -jarfile',
        'unzip -t',
        'sha256sum',
    ):
        if token not in workflow:
            errors.append(f'missing release workflow contract token: {token}')

    for test_name in REQUIRED_RELEASE_TESTS:
        if test_name not in workflow:
            errors.append(f'missing current release test: {test_name}')

    for test_name in OBSOLETE_RELEASE_TESTS:
        if test_name in workflow:
            errors.append(f'obsolete release test still referenced: {test_name}')

    for token in (EXPECTED_PACKAGE, EXPECTED_VERSION_CODE, EXPECTED_VERSION_NAME):
        if token not in preset:
            errors.append(f'export preset does not preserve update contract: {token}')

    if errors:
        print('Release contract validation failed:')
        for error in errors:
            print(f' - {error}')
        return 1

    print('Release contract validation passed.')
    print('Package: com.eghosa.unjam')
    print('Default release: versionCode 2 / versionName 1.0.1')
    print(f'Expected upload certificate SHA-1: {EXPECTED_UPLOAD_SHA1}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
