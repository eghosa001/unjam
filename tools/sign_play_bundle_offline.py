#!/usr/bin/env python3
"""Offline Play AAB signing with a hard-fail key identity gate.

For UNJAM com.eghosa.unjamgam only. Keystores/passwords must NEVER enter GitHub.
The v1.0.12 D8:B5 upload key is NOT enrolled in the current Play listing.
"""
from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import re
import subprocess
import sys
import zipfile

EXPECTED_SHA1 = "65:0D:39:CA:2C:0A:E6:FA:D4:2E:ED:E0:00:DA:13:C7:16:85:AA:2C"
EXPECTED_PACKAGE = "com.eghosa.unjamgam"


def run(args: list[str], *, timeout: int = 120) -> str:
    result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        raise ValueError(f"{Path(args[0]).name} failed (exit {result.returncode})")
    return result.stdout + result.stderr


def sha1_from_text(value: str) -> str:
    certs = re.findall(r"SHA1:\s*([0-9A-Fa-f:]{59})", value)
    if not certs:
        raise ValueError("No SHA-1 certificate fingerprint in keytool output")
    unique = {c.upper() for c in certs}
    if len(unique) != 1:
        raise ValueError("More than one distinct signer certificate detected")
    return unique.pop()


def require_correct_sha1(actual: str) -> None:
    if actual != EXPECTED_SHA1:
        raise ValueError(
            "WRONG UPLOAD KEY: certificate " + actual
            + " is not the 65:0D... certificate enrolled in Google Play. "
            "The old version 12 D8:B5 key must never sign this release."
        )


def verify_aab(path: Path) -> str:
    if not path.is_file():
        raise ValueError("Signed AAB not found")
    with zipfile.ZipFile(path) as bundle:
        if bundle.testzip() is not None:
            raise ValueError("AAB ZIP failed CRC verification")
        signers = [n for n in bundle.namelist()
                   if re.fullmatch(r"META-INF/[^/]+\.(RSA|DSA|EC)", n, re.I)]
        if len(signers) != 1:
            raise ValueError("Expected exactly one AAB JAR signer")
    # jarsigner -verify returns zero with self-signed upload certificates; its
    # unsigned-certificate warning is expected, not a Play-identity match.
    verification = run(["jarsigner", "-verify", str(path)], timeout=90)
    if "jar verified" not in verification.lower():
        raise ValueError("JAR signature verification did not succeed")
    actual = sha1_from_text(run(["keytool", "-printcert", "-jarfile", str(path)]))
    require_correct_sha1(actual)
    return hashlib.sha256(path.read_bytes()).hexdigest()


def preflight_key(keystore: Path, alias: str) -> None:
    # Secret is read only from an environment variable; never command-line
    # arguments, GitHub workflows, provenance files or printed logs.
    if not os.environ.get("UNJAM_ANDROID_KEY_PASSWORD"):
        raise ValueError("Set UNJAM_ANDROID_KEY_PASSWORD in your private environment")
    if not keystore.is_file():
        raise ValueError("Keystore file not found")
    key_metadata = run([
        "keytool", "-list", "-v", "-keystore", str(keystore),
        "-storepass:env", "UNJAM_ANDROID_KEY_PASSWORD", "-alias", alias
    ])
    require_correct_sha1(sha1_from_text(key_metadata))


def assert_unsigned_release(input_aab: Path, badging: Path | None) -> None:
    if badging is None or not badging.is_file():
        raise ValueError("Exact-version APK package-badging.txt from the SAME export run is required")
    with zipfile.ZipFile(input_aab) as bundle:
        if bundle.testzip() is not None:
            raise ValueError("Unsigned input AAB is damaged")
        if any(re.fullmatch(r"META-INF/[^/]+\.(SF|RSA|DSA|EC)", n, re.I)
               for n in bundle.namelist()):
            raise ValueError("Input AAB is already signed; refuse to layer signatures")
    if badging is not None:
        text = badging.read_text()
        if ("name='" + EXPECTED_PACKAGE + "'") not in text:
            raise ValueError("Unexpected Android package; wrong Play app")
        if "versionCode='13' versionName='1.0.13'" not in text:
            raise ValueError("Wrong release version; expected 1.0.13 (code 13)")


def sign(input_aab: Path, output_aab: Path, key: Path, alias: str, badging: Path | None) -> str:
    if input_aab.resolve() == output_aab.resolve():
        raise ValueError("Input and output AAB paths must be different")
    preflight_key(key, alias)
    assert_unsigned_release(input_aab, badging)
    if output_aab.exists():
        raise ValueError("Output already exists; refusing to overwrite a release")
    output_aab.parent.mkdir(parents=True, exist_ok=True)
    try:
        run([
            "jarsigner", "-keystore", str(key),
            "-storepass:env", "UNJAM_ANDROID_KEY_PASSWORD",
            "-keypass:env", "UNJAM_ANDROID_KEY_PASSWORD",
            "-sigalg", "SHA256withRSA", "-digestalg", "SHA-256",
            "-signedjar", str(output_aab), str(input_aab), alias
        ], timeout=180)
        result = verify_aab(output_aab)
        # AAB signing adds only signature metadata; all original payload
        # bytes and their CRCs must remain unchanged.
        with zipfile.ZipFile(input_aab) as before, zipfile.ZipFile(output_aab) as after:
            for name in before.namelist():
                a, b = before.getinfo(name), after.getinfo(name)
                if (a.CRC, a.file_size) != (b.CRC, b.file_size):
                    raise ValueError("Signing unexpectedly changed application payload: " + name)
    except Exception:
        output_aab.unlink(missing_ok=True)
        raise
    return result


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--verify-only", type=Path, help="Check the actual final signed AAB")
    p.add_argument("--unsigned", type=Path)
    p.add_argument("--output", type=Path)
    p.add_argument("--keystore", type=Path)
    p.add_argument("--alias", default="unjam-upload-fresh")
    p.add_argument("--package-badging", type=Path, help="Original APK badging from same export run")
    a = p.parse_args()
    try:
        if a.verify_only is not None:
            digest = verify_aab(a.verify_only)
        elif a.unsigned and a.output and a.keystore:
            digest = sign(a.unsigned, a.output, a.keystore, a.alias, a.package_badging)
        else:
            p.error("Use --verify-only FILE or --unsigned FILE --output FILE --keystore JKS")
        print("PLAY_UPLOAD_SIGNING_OK")
        print("Required Play package: " + EXPECTED_PACKAGE + "; release version: 1.0.13 (13)")
        print("SHA1: " + EXPECTED_SHA1)
        print("AAB SHA256: " + digest)
        return 0
    except (ValueError, OSError, subprocess.TimeoutExpired, zipfile.BadZipFile) as exc:
        print("PLAY_UPLOAD_SIGNING_REJECTED: " + str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
