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
USER_AGENT = "UNJAM-Monetization-Readiness/2.0"


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


def post_json(url: str, body: dict, api_key: str, timeout: float = 20.0) -> tuple[int, str, str]:
    payload = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=payload,
        method="POST",
        headers={
            "User-Agent": USER_AGENT,
            "Accept": "application/json",
            "Content-Type": "application/json",
            "apikey": api_key,
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            text = response.read(256_000).decode("utf-8", "replace")
            return int(response.status), response.geturl(), text
    except urllib.error.HTTPError as exc:
        text = exc.read(32_000).decode("utf-8", "replace")
        return int(exc.code), exc.geturl(), text
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


def project_setting(name: str) -> str:
    text = Path("project.godot").read_text(encoding="utf-8")
    match = re.search(rf'^{re.escape(name)}="([^"]*)"

def main() -> int:
    supabase_url = (os.environ.get("UNJAM_SUPABASE_URL", "") or project_setting("supabase_url")).strip().rstrip("/")
    supabase_key = (os.environ.get("UNJAM_SUPABASE_PUBLISHABLE_KEY", "") or project_setting("supabase_publishable_key")).strip()
    developer_website = os.environ.get("UNJAM_DEVELOPER_WEBSITE_URL", "")

    parsed_supabase = require_https_url(supabase_url, "UNJAM_SUPABASE_URL")
    if not parsed_supabase.hostname.endswith(".supabase.co"):
        fail("UNJAM_SUPABASE_URL must be a managed Supabase project URL")
    if not supabase_key:
        fail("UNJAM_SUPABASE_PUBLISHABLE_KEY is not configured")
    function_url = supabase_url + "/functions/v1/unjam-purchase"

    developer = require_https_url(developer_website, "UNJAM_DEVELOPER_WEBSITE_URL")
    app_ads_url = urllib.parse.urlunparse((developer.scheme, developer.netloc, "/app-ads.txt", "", "", ""))

    privacy_url = privacy_url_from_project()
    require_https_url(privacy_url, "monetization/privacy_policy_url")

    status, final_url, body = post_json(function_url, {"action": "readiness"}, supabase_key)
    if status != 200:
        fail(f"Supabase purchase verifier readiness returned HTTP {status} at {final_url}")
    try:
        readiness = json.loads(body)
    except json.JSONDecodeError:
        fail("Supabase purchase verifier readiness did not return JSON")
    dependencies = readiness.get("dependencies", {})
    if (
        readiness.get("ok") is not True
        or dependencies.get("postgres") is not True
        or dependencies.get("google_play") is not True
        or readiness.get("package_name") != EXPECTED_PACKAGE
    ):
        fail("Purchase verifier dependencies are not ready for Supabase Postgres + Google Play Purchases API")
    print(f"PASS Supabase purchase verifier readiness: {final_url}")

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
, text, flags=re.MULTILINE)
    if not match:
        fail(f"{name} is missing from project.godot")
    return match.group(1)


def privacy_url_from_project() -> str:
    return project_setting("privacy_policy_url")


def main() -> int:
    supabase_url = os.environ.get("UNJAM_SUPABASE_URL", "").strip().rstrip("/")
    supabase_key = os.environ.get("UNJAM_SUPABASE_PUBLISHABLE_KEY", "").strip()
    developer_website = os.environ.get("UNJAM_DEVELOPER_WEBSITE_URL", "")

    parsed_supabase = require_https_url(supabase_url, "UNJAM_SUPABASE_URL")
    if not parsed_supabase.hostname.endswith(".supabase.co"):
        fail("UNJAM_SUPABASE_URL must be a managed Supabase project URL")
    if not supabase_key:
        fail("UNJAM_SUPABASE_PUBLISHABLE_KEY is not configured")
    function_url = supabase_url + "/functions/v1/unjam-purchase"

    developer = require_https_url(developer_website, "UNJAM_DEVELOPER_WEBSITE_URL")
    app_ads_url = urllib.parse.urlunparse((developer.scheme, developer.netloc, "/app-ads.txt", "", "", ""))

    privacy_url = privacy_url_from_project()
    require_https_url(privacy_url, "monetization/privacy_policy_url")

    status, final_url, body = post_json(function_url, {"action": "readiness"}, supabase_key)
    if status != 200:
        fail(f"Supabase purchase verifier readiness returned HTTP {status} at {final_url}")
    try:
        readiness = json.loads(body)
    except json.JSONDecodeError:
        fail("Supabase purchase verifier readiness did not return JSON")
    dependencies = readiness.get("dependencies", {})
    if (
        readiness.get("ok") is not True
        or dependencies.get("postgres") is not True
        or dependencies.get("google_play") is not True
        or readiness.get("package_name") != EXPECTED_PACKAGE
    ):
        fail("Purchase verifier dependencies are not ready for Supabase Postgres + Google Play Purchases API")
    print(f"PASS Supabase purchase verifier readiness: {final_url}")

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
