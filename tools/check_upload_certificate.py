#!/usr/bin/env python3
"""Check a private JKS against the upload certificate enrolled in Play.

Never logs or stores the keystore password. This does not sign a build.
"""
import argparse
import os
import re
import subprocess
import sys


def normalize(value: str) -> str:
    normalized = value.strip().replace(":", "").lower()
    if not re.fullmatch(r"[0-9a-f]{40}", normalized):
        raise ValueError("Expected SHA-1 must contain exactly 40 hex digits")
    return normalized


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("keystore")
    parser.add_argument("--alias", required=True)
    parser.add_argument("--expected-sha1", required=True,
                        help="Upload certificate SHA-1 shown in Google Play App integrity")
    args = parser.parse_args()
    password = os.environ.get("UNJAM_ANDROID_KEY_PASSWORD")
    if not password:
        print("Missing UNJAM_ANDROID_KEY_PASSWORD environment variable", file=sys.stderr)
        return 2
    try:
        expected = normalize(args.expected_sha1)
        proc = subprocess.run(
            ["keytool", "-list", "-v", "-keystore", args.keystore,
             "-storepass:env", "UNJAM_ANDROID_KEY_PASSWORD", "-alias", args.alias],
            capture_output=True, text=True, timeout=25, check=False
        )
        # keytool reads the password from process environment rather than argv.
        # Do not echo subprocess output: it can contain private keystore metadata.
        match = re.search(r"SHA1:\s*([A-Fa-f0-9:]+)", proc.stdout)
        if proc.returncode or not match:
            print("Keystore could not be verified", file=sys.stderr)
            return 3
        if normalize(match.group(1)) != expected:
            print("FAIL: Key does not match current Play upload certificate", file=sys.stderr)
            return 4
    except (OSError, ValueError, subprocess.TimeoutExpired) as err:
        print(f"Keystore preflight failed: {type(err).__name__}", file=sys.stderr)
        return 5
    print("UPLOAD_CERTIFICATE_MATCH: signature identity verified for selected Play listing")
    return 0


if __name__ == "__main__":
    sys.exit(main())
