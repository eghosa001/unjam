#!/usr/bin/env bash
set -euo pipefail

ADMOB_VERSION="5.1.0"
GODOT_ADMOB_TEMPLATE_VERSION="4.7.2"
BILLING_VERSION="3.3.0"
CACHE_DIR=".plugin-cache"

mkdir -p "$CACHE_DIR" addons

# Google Play Billing.
curl -fL "https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/download/${BILLING_VERSION}/godot-google-play-billing.zip" -o "$CACHE_DIR/billing.zip"
rm -rf "$CACHE_DIR/billing"
mkdir -p "$CACHE_DIR/billing"
unzip -oq "$CACHE_DIR/billing.zip" -d "$CACHE_DIR/billing"
BILLING_ADDON=$(find "$CACHE_DIR/billing" -type d -path "*/addons/GodotGooglePlayBilling" -print -quit)
if [[ -z "$BILLING_ADDON" ]]; then
  BILLING_FILE=$(find "$CACHE_DIR/billing" -type f -name BillingClient.gd -print -quit)
  test -n "$BILLING_FILE"
  BILLING_ADDON=$(dirname "$BILLING_FILE")
fi
test -f "$BILLING_ADDON/plugin.cfg"
rm -rf addons/GodotGooglePlayBilling
mkdir -p addons/GodotGooglePlayBilling
cp -R "$BILLING_ADDON/." addons/GodotGooglePlayBilling/
test -f addons/GodotGooglePlayBilling/BillingClient.gd
test -f addons/GodotGooglePlayBilling/plugin.cfg
test -f addons/GodotGooglePlayBilling/bin/debug/GodotGooglePlayBilling-debug.aar
test -f addons/GodotGooglePlayBilling/bin/release/GodotGooglePlayBilling-release.aar

# Poing Studios AdMob editor/GDScript plugin.
curl -fL "https://github.com/poingstudios/godot-admob-plugin/releases/download/v${ADMOB_VERSION}/poing-godot-admob-v${ADMOB_VERSION}.zip" -o "$CACHE_DIR/admob.zip"
rm -rf "$CACHE_DIR/admob"
mkdir -p "$CACHE_DIR/admob"
unzip -oq "$CACHE_DIR/admob.zip" -d "$CACHE_DIR/admob"
ADMOB_ADDONS=$(find "$CACHE_DIR/admob" -type d -name addons -print -quit)
test -n "$ADMOB_ADDONS"
rm -rf addons/admob
cp -R "$ADMOB_ADDONS/admob" addons/

# Native Android package matched to Godot 4.7.2.
curl -fL "https://github.com/poingstudios/godot-admob-plugin/releases/download/v${ADMOB_VERSION}/android-template-v${GODOT_ADMOB_TEMPLATE_VERSION}.zip" -o "$CACHE_DIR/admob-android.zip"
rm -rf "$CACHE_DIR/admob-android"
mkdir -p "$CACHE_DIR/admob-android"
unzip -oq "$CACHE_DIR/admob-android.zip" -d "$CACHE_DIR/admob-android"
rm -rf addons/admob/android/bin
mkdir -p addons/admob/android/bin
ADMOB_ANDROID_PACKAGE=$(find "$CACHE_DIR/admob-android" -type f -name package.gd -print -quit)
test -n "$ADMOB_ANDROID_PACKAGE"
ADMOB_ANDROID_ROOT=$(dirname "$ADMOB_ANDROID_PACKAGE")
cp -R "$ADMOB_ANDROID_ROOT/." addons/admob/android/bin/

test -f addons/admob/plugin.cfg
test -f addons/GodotGooglePlayBilling/BillingClient.gd
test -f addons/admob/android/bin/package.gd
test -f addons/admob/android/bin/ads/poing_godot_admob_ads.gd
test "$(find addons/admob/android/bin/ads/libs -type f -name '*.aar' | wc -l)" -gt 0

echo "Installed Google Play Billing ${BILLING_VERSION}, Poing AdMob ${ADMOB_VERSION}, and Android template ${GODOT_ADMOB_TEMPLATE_VERSION}."
echo "The maintained UNJAM provider remains at addons/unjam_admob_provider.gd."
