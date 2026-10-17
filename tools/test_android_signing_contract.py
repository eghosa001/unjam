from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = (ROOT / ".github" / "workflows" / "android-release.yml").read_text()
SIGNER = (ROOT / "tools" / "sign_play_bundle_offline.py").read_text()


def main() -> int:
    errors = []
    if 'default: 1.0.14' not in WORKFLOW or 'default: 14' not in WORKFLOW:
        errors.append("production workflow defaults must be version 1.0.14 / code 14")
    if "name: unjam-release-aab-production-v14" not in WORKFLOW:
        errors.append("production artifact must be uniquely named for v14")
    if "D8:B5" in WORKFLOW or "D8:B5" in SIGNER:
        errors.append("the retired D8:B5 certificate must not be accepted by release code")
    if "65:0D:39:CA:2C:0A:E6:FA:D4:2E:ED:E0:00:DA:13:C7:16:85:AA:2C" not in SIGNER:
        errors.append("signing guard must pin the registered upload certificate")
    if "rm -rf build/android" not in WORKFLOW:
        errors.append("release must clear prior Android artifacts before export")
    if errors:
        print("ANDROID_SIGNING_CONTRACT_FAILED")
        for error in errors:
            print(f" - {error}")
        return 1
    print("ANDROID_SIGNING_CONTRACT_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
