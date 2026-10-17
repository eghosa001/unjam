# UNJAM Google Play upload signing identity — 17 October 2026

## Which upload key is enrolled?

The latest owner-provided Google Play closed-testing screenshot for the active
`com.eghosa.unjamgam` listing explicitly requires upload-certificate SHA-1:

`65:0D:39:CA:2C:0A:E6:FA:D4:2E:ED:E0:00:DA:13:C7:16:85:AA:2C`

This is **the upload certificate**, not the Google-managed app-signing
certificate. It is the only fingerprint an offline-signed AAB may use for this
listing unless Play Console App Integrity explicitly changes.

## What really happened in version 12?

The surviving `UNJAM_v1.0.12_RELEASE_SIGNED_AFTER_KEY_RESET.aab` was built
unsigned in GitHub Actions run 38776695800 (source revision
`7d9f2ddf21b0a8d1f96dc7c70ee5bc5ec8c1c483`), then JAR signed privately
using a replacement key. Its AAB's **actual embedded** upload certificate SHA-1
is `D8:B5:8B:5F:0C:F0:45:82:19:96:02:33:79:29:17:DC:16:A1:8E:33`.
It is correctly JAR-signed, but that certificate does **not** match the
65:0D... fingerprint shown on the current Play Console. Reusing that v12 key
is precisely the rejection the owner reports.

The useful v12 practice to preserve is **production-configured unsigned Android
export followed by private offline signing**, NOT the v12 replacement key.
Keep the key and passwords out of GitHub and use the currently enrolled key.

## Mandatory no-surprises v13 signing workflow

1. Export APK/AAB **unsigned** from an exact code commit; archive
   `source-commit.txt`, `unsigned.sha256`, and
   `package-badging.txt` in the same GitHub build artifact.
2. Read the active Play Console upload SHA-1, not an old keystore filename.
3. Run `tools/sign_play_bundle_offline.py` from a private workstation or
   isolated runtime. It **rejects the keystore before signing** unless its
   certificate is 65:0D..., refuses previously signed AAB inputs, checks
   package/version from the same export run, and **re-verifies the signer in
   the output AAB**, JAR integrity and unchanged application payload.
4. For current version 13:
   `UNJAM_ANDROID_KEY_PASSWORD` must be provided privately as an environment
   variable. Run:
   ```sh
   python3 tools/sign_play_bundle_offline.py \
       --unsigned build/android/UNJAM-v13-unsigned.aab \
       --output build/android/UNJAM-v13-PLAY-650D-UPLOAD.aab \
       --keystore /PRIVATE/PATH/UNJAM-upload-key-after-reset.jks \
       --alias unjam-upload-fresh \
       --package-badging build/android/package-badging.txt
   python3 tools/sign_play_bundle_offline.py \
       --verify-only build/android/UNJAM-v13-PLAY-650D-UPLOAD.aab
   ```
5. Download the **final distinctly named AAB** to the device and select
   that file in the Play Console *Upload* picker. Never rely only on the
   displayed filename or a previous Downloads folder entry.
6. A green offline signature check proves the file's identity, but **does
   not prove that the browser uploaded those bytes** or that Google Play
   accepted the release.

Do **not** reset the Play upload key, change the Android package name or
publish a higher versionCode merely to work around this mismatch. First
determine whether Play Console is processing the same file SHA-256.

Never commit the keystore or passwords. The v12 D8:B5 key must be rejected
for this app even though its AAB JAR signature is technically valid.
