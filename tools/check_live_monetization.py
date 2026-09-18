#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

EXPECTED_APP_ADS = "google.com, pub-7517898921176341, DIRECT, f08c47fec0942fa0"
EXPECTED_PACKAGE = "com.eghosa.unjamgam"
USER_AGENT = "UNJAM-Monetization-Readiness/1.0"


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def fetch(url: str, timeout: float = 20.0) -> tuple[int, str, str]:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "*/*"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            body = response.read(256_000).decode("utf-8", "replace")
            return int(response.status), response.geturl(), body
    except urllib.error.HTTPError as exc:
        body = exc.read(32_000).decode("utf-8", "replace")
        return int(exc.code), exc.geturl(), body
    except Exception as exc:
        fail(f"Could not reach {url}: {exc}")


def require_https_url(value: str, label: str) -> urllib.parse.ParseResult:
    value = value.strip()
    if not value:
        fail(f"{label} is not configured")
    parsed = urllib.parse.urlparse(value)
    if parsed.scheme != "https" or not parsed.hostname:
        fail(f"{label} must be an https:// URL with a hostname")
    return parsed


def privacy_url_from_project() -> str:
    text = Path("project.godot").read_text(encoding="utf-8")
    match = re.search(r'^privacy_policy_url="([^"]+)"$', text, flags=re.MULTILINE)
    if not match:
        fail("monetization/privacy_policy_url is missing from project.godot")
    return match.group(1)


def main() -> int:
    verify_url = os.environ.get("UNJAM_PURCHASE_VERIFICATION_URL", "")
    developer_website = os.environ.get("UNJAM_DEVELOPER_WEBSITE_URL", "")

    verify = require_https_url(verify_url, "UNJAM_PURCHASE_VERIFICATION_URL")
    if not verify.path.rstrip("/").endswith("/verify"):
        fail("UNJAM_PURCHASE_VERIFICATION_URL must end in /verify")

    developer = require_https_url(developer_website, "UNJAM_DEVELOPER_WEBSITE_URL")
    # AdMob crawls the hostname root from the developer website in the store
    # listing. A project subpath such as /unjam/ is intentionally ignored here.
    app_ads_url = urllib.parse.urlunparse((developer.scheme, developer.netloc, "/app-ads.txt", "", "", ""))

    privacy_url = privacy_url_from_project()
    require_https_url(privacy_url, "monetization/privacy_policy_url")

    verifier_root = verify_url.rsplit("/verify", 1)[0]
    health_url = verifier_root.rstrip("/") + "/healthz"
    readiness_url = verifier_root.rstrip("/") + "/readiness"

    status, final_url, body = fetch(health_url)
    if status != 200:
        fail(f"Purchase verifier health check returned HTTP {status} at {final_url}")
    try:
        health = json.loads(body)
    except json.JSONDecodeError:
        fail("Purchase verifier /healthz did not return JSON")
    if health.get("ok") is not True:
        fail("Purchase verifier /healthz did not return {\"ok\": true}")
    print(f"PASS purchase verifier health: {final_url}")

    status, final_url, body = fetch(readiness_url)
    if status != 200:
        fail(f"Purchase verifier dependency readiness returned HTTP {status} at {final_url}")
    try:
        readiness = json.loads(body)
    except json.JSONDecodeError:
        fail("Purchase verifier /readiness did not return JSON")
    dependencies = readiness.get("dependencies", {})
    if (
        readiness.get("ok") is not True
        or dependencies.get("firestore") is not True
        or dependencies.get("google_play") is not True
        or readiness.get("package_name") != EXPECTED_PACKAGE
    ):
        fail("Purchase verifier dependencies are not ready for Firestore + Google Play Purchases API")
    print(f"PASS purchase verifier dependencies: {final_url}")

    status, final_url, body = fetch(app_ads_url)
    if status != 200:
        fail(f"AdMob app-ads.txt returned HTTP {status} at {final_url}")
    normalized = {line.strip() for line in body.splitlines() if line.strip() and not line.lstrip().startswith("#")}
    if EXPECTED_APP_ADS not in normalized:
        fail(f"app-ads.txt at hostname root is missing expected publisher record: {EXPECTED_APP_ADS}")
    print(f"PASS app-ads.txt hostname-root record: {final_url}")

    status, final_url, body = fetch(privacy_url)
    if status != 200:
        fail(f"Privacy policy returned HTTP {status} at {final_url}")
    lowered = body.lower()
    if "unjam" not in lowered or "privacy" not in lowered:
        fail("Privacy policy is reachable but does not look like the UNJAM privacy policy")
    print(f"PASS privacy policy: {final_url}")

    preset = Path("export_presets.cfg").read_text(encoding="utf-8")
    if f'package/unique_name="{EXPECTED_PACKAGE}"' not in preset:
        fail(f"Android package is not {EXPECTED_PACKAGE}")

    print("LIVE MONETIZATION READINESS PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
