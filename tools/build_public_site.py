#!/usr/bin/env python3
"""Build UNJAM's public, static developer site for Render and local smoke tests."""
from __future__ import annotations

import argparse
import os
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ORIGIN = "https://unjam-eghosa.onrender.com"


def build(output: Path, origin: str) -> None:
    parts = urlsplit(origin)
    if parts.scheme != "https" or not parts.hostname or parts.path not in ("", "/"):
        raise ValueError("UNJAM_PUBLIC_SITE_ORIGIN must be an HTTPS hostname without a path")
    origin = origin.rstrip("/")
    if output.exists():
        shutil.rmtree(output)
    (output / "assets").mkdir(parents=True)
    for name in ("index", "privacy", "support"):
        source = (ROOT / f"{name}.md").read_text(encoding="utf-8")
        if not source.startswith("---\n"):
            raise ValueError(f"{name}.md is missing opening YAML frontmatter")
        end = source.find("\n---\n", 4)
        if end == -1:
            raise ValueError(f"{name}.md is missing closing YAML frontmatter")
        html = source[end + len("\n---\n"):].lstrip()
        if not html.lower().startswith("<!doctype html>") or "</html>" not in html.lower():
            raise ValueError(f"{name}.md is not a complete HTML document")
        (output / f"{name}.html").write_text(html, encoding="utf-8")
    for name in ("site.css", "icon.svg"):
        shutil.copy2(ROOT / "assets" / name, output / "assets" / name)
    ads = (ROOT / "app-ads.txt").read_text(encoding="utf-8").strip() + "\n"
    if "google.com, pub-7517898921176341, DIRECT, f08c47fec0942fa0" not in ads:
        raise ValueError("Authorized AdMob seller record is missing")
    (output / "app-ads.txt").write_text(ads, encoding="utf-8")
    (output / "robots.txt").write_text(
        f"User-agent: *\nAllow: /\nSitemap: {origin}/sitemap.xml\n",
        encoding="utf-8",
    )
    ns = "http://www.sitemaps.org/schemas/sitemap/0.9"
    ET.register_namespace("", ns)
    urlset = ET.Element(f"{{{ns}}}urlset")
    for route in ("", "privacy.html", "support.html"):
        loc = ET.SubElement(ET.SubElement(urlset, f"{{{ns}}}url"), f"{{{ns}}}loc")
        loc.text = f"{origin}/{route}"
    ET.ElementTree(urlset).write(output / "sitemap.xml", encoding="utf-8", xml_declaration=True)
    (output / ".nojekyll").write_text("", encoding="utf-8")
    for route in ("index.html", "privacy.html", "support.html", "app-ads.txt", "robots.txt", "sitemap.xml", "assets/site.css", "assets/icon.svg"):
        if not (output / route).is_file():
            raise ValueError(f"Missing public site artifact: {route}")
    print(f"UNJAM public website built: {output} ({origin})")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="public")
    parser.add_argument("--origin", default=os.environ.get("UNJAM_PUBLIC_SITE_ORIGIN", DEFAULT_ORIGIN))
    args = parser.parse_args()
    build(Path(args.output).resolve(), args.origin)
