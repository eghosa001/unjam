FROM python:3.12-alpine AS site-builder
WORKDIR /work
COPY index.md privacy.md support.md app-ads.txt ./
COPY assets/site.css assets/icon.svg ./assets/
COPY tools/build_public_site.py ./tools/build_public_site.py
RUN python tools/build_public_site.py --output /out

FROM nginx:stable-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=site-builder /out/ /usr/share/nginx/html/
EXPOSE 8080
