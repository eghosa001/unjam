# UNJAM — owner-confirmed working upload-key variant

## Play upload reported successful — 14 November 2026

The owner confirmed that **`UNJAM-v1.0.16-latest-signed-D8B5-alternate.aab`** is the variant that worked for the existing Google Play app.

- Application ID: `com.eghosa.unjamgam`
- Version name / version code: `1.0.16` / `16`
- **Working upload-key variant:** D8:B5 alternate
- Signing certificate SHA-1: **`D8:B5:8B:5F:0C:F0:45:82:19:96:02:33:79:29:17:DC:16:A1:8E:33`**
- Source commit: `aaf17c79dd84c917f98cc3defd6647b647174fc9`
- Successful source regression/export run: https://github.com/eghosa001/unjam/actions/runs/43599442295
- Owner's stored signed AAB: https://drive.google.com/file/d/1zy4YSo6l1AZffpFyD13ZA6YGuy5b4H6u/view
- Pre-upload artifact checks: JAR signature and ZIP integrity passed

This is an **owner-reported Google Play success**, not an independent Play Console API readback. A prior Play email dated 17 October 2026 mentioned a different reset-certificate fingerprint beginning `D8:7F:B0:3E`. For subsequent releases, verify the current **upload certificate** in Play Console > App integrity; it is distinct from the Google Play app-signing certificate. Do not replace the owner-confirmed D8:B5 key merely because of historical contradictory notes.

## Future release checklist

1. Keep the existing **D8:B5 private keystore** and its credentials securely backed up **outside the Git repository**. Do not generate a new key for routine updates.
2. Preserve the package `com.eghosa.unjamgam`; increase `versionCode` above the last code accepted by Play (do not reuse 16).
3. Produce a fresh release AAB from a fully validated source commit with the required Android SDK, ABI, and monetization checks.
4. Confirm the currently registered upload fingerprint in Play Console. Use the matching D8:B5 keystore only when the fingerprint matches.
5. For GitHub Actions configure `UNJAM_ANDROID_UPLOAD_SHA1` with the verified SHA-1 and securely supply `UNJAM_ANDROID_KEYSTORE_BASE64`, `UNJAM_ANDROID_KEY_ALIAS`, and `UNJAM_ANDROID_KEY_PASSWORD`. **Never commit key material, passwords, or full signing secrets.**
6. Check AAB package, version, certificate SHA-1, JAR signature and ZIP integrity before submitting to Internal Testing.
7. Verify acceptance and test the Play-delivered build before production rollout.

The binary AAB is retained on Google Drive, **not as a Git source file**. GitHub records the working variant and repeatable process.
