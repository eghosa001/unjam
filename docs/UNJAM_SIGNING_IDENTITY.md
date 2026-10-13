# Signing certificate identity (verified 13 October 2026)

The last **verified signed production UNJAM release** available in the user's archive is version **1.0.10**, versionCode **10**, package **com.eghosa.unjamgam**.

The AAB signature was independently checked with Java `jarsigner` and `keytool`.

- Last signed AAB upload-certificate SHA-1: `95:CD:20:58:DB:4E:44:0E:B6:1C:82:8C:D8:16:E3:31:99:4E:68:03`.
- Archived fresh replacement keystore SHA-1: `65:0D:39:CA:2C:0A:E6:FA:D4:2E:ED:E0:00:DA:13:C7:16:85:AA:2C`.

These are **different keys**. The original v10 signer private keystore was not found among the accessible archived JKS files. A signed AAB does not contain the private signing key.

Do not choose between the two based on filenames. Verify the currently enrolled **upload key certificate** under Google Play Console → App integrity for the active listing. Only use the JKS matching that current Play upload key, and keep the file and credentials outside GitHub.

Status: the production release workflow has no configured keystore secret; signed v1.0.11 release is blocked. Do not claim Google Play acceptance from test APK CI.
