#!/usr/bin/env bash
set -euo pipefail
mkdir -p .plugin-cache addons
curl -fL https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/download/3.3.0/godot-google-play-billing.zip -o .plugin-cache/billing.zip
unzip -oq .plugin-cache/billing.zip -d .plugin-cache/billing
if [ -d .plugin-cache/billing/addons/GodotGooglePlayBilling ]; then
  cp -R .plugin-cache/billing/addons/GodotGooglePlayBilling addons/
else
  BILLING_DIR=$(find .plugin-cache/billing -type d -path '*/addons/GodotGooglePlayBilling' | head -1)
  test -n "$BILLING_DIR"
  cp -R "$BILLING_DIR" addons/
fi
curl -fL https://github.com/poingstudios/godot-admob-plugin/releases/download/v5.1.0/poing-godot-admob-v5.1.0.zip -o .plugin-cache/admob.zip
unzip -oq .plugin-cache/admob.zip -d .plugin-cache/admob
ADMOB_ADDONS=$(find .plugin-cache/admob -type d -name addons | head -1)
test -n "$ADMOB_ADDONS"
cp -R "$ADMOB_ADDONS"/* addons/
echo "Installed GodotGooglePlayBilling 3.3.0 and Poing AdMob 5.1.0. Enable the plugins in Godot and install the matching Android build template before a production Android export."
