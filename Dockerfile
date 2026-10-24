FROM python:3.12-alpine AS site-builder
WORKDIR /work
COPY index.md privacy.md support.md app-ads.txt ./
COPY assets/site.css assets/icon.svg ./assets/
RUN python - <<'PY'
from pathlib import Path
from shutil import copy2
out = Path("/out")
(out / "assets").mkdir(parents=True)
for page in ("index", "privacy", "support"):
    source = Path(f"/work/{page}.md").read_text(encoding="utf-8")
    if not source.startswith("---\n"):
        raise ValueError(f"{page}.md must begin with Jekyll front matter")
    end = source.find("\n---\n", 4)
    if end < 0:
        raise ValueError(f"{page}.md is missing closing front matter")
    html = source[end + 5:].lstrip()
    if not html.lower().startswith("<!doctype html>"):
        raise ValueError(f"{page}.md has no HTML document")
    (out / f"{page}.html").write_text(html, encoding="utf-8")
for name in ("site.css", "icon.svg"):
    copy2(Path("/work/assets") / name, out / "assets" / name)
copy2("/work/app-ads.txt", out / "app-ads.txt")
(out / "robots.txt").write_text(
    "User-agent: *\nAllow: /\nSitemap: https://unjam-site-prod-production.up.railway.app/sitemap.xml\n",
    encoding="utf-8",
)
(out / "sitemap.xml").write_text(
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
    + "".join(
        f"  <url><loc>https://unjam-site-prod-production.up.railway.app/{path}</loc></url>\n"
        for path in ("", "privacy.html", "support.html")
    )
    + "</urlset>\n",
    encoding="utf-8",
)
PY

FROM nginx:stable-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=site-builder /out/ /usr/share/nginx/html/
EXPOSE 8080
