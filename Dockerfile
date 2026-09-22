FROM python:3.12-alpine
WORKDIR /site
COPY index.md /site/index.html
COPY privacy.md /site/privacy.html
COPY support.md /site/support.html
COPY app-ads.txt /site/app-ads.txt
EXPOSE 8080
CMD ["sh","-c","python -m http.server ${PORT:-8080} --bind 0.0.0.0 --directory /site"]
