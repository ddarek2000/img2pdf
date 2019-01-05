FROM python:alpine
WORKDIR /usr/src/app

ENV LANG=C.UTF-8

COPY . /app

RUN apk update \
        && apk add --no-cache bash \
        && apk add --no-cache jpeg-dev \
        && apk add --no-cache zlib-dev \
        && apk add --no-cache imagemagick \
        && apk add --no-cache py-pillow \
        && apk add --no-cache py-img2pdf \
        && apk add --no-cache ocrmypdf \
        && apk add --no-cache unpaper \
        && apk add --no-cache tesseract-ocr \
#       && apk add --no-cache tesseract-ocr-data-spa \
        && rm -rf /var/cache/apk/* \
        && python3 -m venv --system-site-packages /appenv \
 && addgroup -g 98  docker \
 && mkdir /home/docker \
 && adduser -D -u 99 -G docker docker \
 && chown docker:docker /home/docker

VOLUME /home/docker

USER docker
WORKDIR /home/docker

CMD ["apk info"]
ENTRYPOINT ["/app/docker-wrapper.sh"]
