# Fresh Google Play v1 setup

This repository is configured for a replacement Google Play listing starting at `versionName 1.0.0` / `versionCode 1`.

## Owner-controlled setup

1. Create the replacement app in Google Play Console.
2. Keep package `com.eghosa.unjam` only if Play accepts it for the replacement listing. If Play rejects the package as already used, stop before configuring billing/AdMob and update the package in the repository first.
3. Use Play App Signing and generate a new RSA upload key for this replacement app.
4. Add the following GitHub Actions secrets:
   - `UNJAM_ANDROID_KEYSTORE_BASE64`: base64 of the new upload keystore file.
   - `UNJAM_ANDROID_KEY_ALIAS`: the alias inside the keystore.
   - `UNJAM_ANDROID_KEY_PASSWORD`: the keystore/key password used by the release workflow.
   - `UNJAM_ANDROID_UPLOAD_SHA1`: SHA-1 fingerprint of the new upload certificate, colon-delimited.
   - `UNJAM_PURCHASE_VERIFICATION_URL`: HTTPS endpoint used by the app to verify Google Play purchases server-side.
5. In the replacement Play app, create the one-time products used by UNJAM: `unjam_remove_ads`, `unjam_starter_pack`, `unjam_coins_500`, `unjam_coins_1500`, and `unjam_coins_4000`.
6. Complete the Play Console app-content declarations truthfully for a casual puzzle game, including ads, Data Safety, target audience and content rating.
7. Run the GitHub Actions workflow `Android Production Release` with `version_name=1.0.0` and `version_code=1` only after all secrets above are configured.
8. Upload the resulting verified release AAB to Internal Testing first. After the first accepted upload, never reuse version code 1 for a different bundle.

## New upload key commands

Generate a new upload key locally and keep secure backups:

```bash
keytool -genkeypair -v -keystore unjam-upload-v1.jks -alias unjam-upload -keyalg RSA -keysize 2048 -validity 10000
```

Print the SHA-1 fingerprint for `UNJAM_ANDROID_UPLOAD_SHA1`:

```bash
keytool -list -v -keystore unjam-upload-v1.jks -alias unjam-upload
```

Create the base64 value for `UNJAM_ANDROID_KEYSTORE_BASE64` without committing the keystore:

```bash
base64 -w 0 unjam-upload-v1.jks
```

On PowerShell use:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("unjam-upload-v1.jks"))
```

Do not paste the private keystore or its password into issues, commits, chat screenshots, or source files.
