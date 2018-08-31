#!/bin/sh
FROM alpine:3.7

ENV BUILD_PACKAGES postgresql-dev graphviz-dev graphviz build-base git pkgconfig \
python3-dev libxml2-dev jpeg-dev libressl-dev libffi-dev libxslt-dev nodejs py3-lxml \
py3-magic postgresql-client poppler-utils antiword vim

ENV EVL_VERSION=1.0.0-1 \
    EVL_URL=https://github.com/interlegis/evl.git

RUN apk update --update-cache && apk upgrade

RUN apk --update add fontconfig ttf-dejavu && fc-cache -fv

RUN apk add --no-cache python3 nginx tzdata && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    rm -r /root/.cache && \
    rm -f /etc/nginx/conf.d/*

RUN mkdir -p /var/interlegis/evl && \
    apk add --update --no-cache $BUILD_PACKAGES && \
    npm install -g bower && \
    npm cache verify

RUN cd /tmp \
 && git clone ${EVL_URL} --depth=1 --branch ${EVL_VERSION} \
 && mv /tmp/evl /var/interlegis 

WORKDIR /var/interlegis/evl/

COPY start.sh /var/interlegis/evl/
COPY busy-wait.sh /var/interlegis/evl/
COPY create_admin.py /var/interlegis/evl/
COPY genkey.py /var/interlegis/evl/
COPY gunicorn_start.sh /var/interlegis/evl/
COPY config/nginx/evl.conf /etc/nginx/conf.d
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf

RUN pip install -r /var/interlegis/evl/requirements.txt --upgrade setuptools && \
    rm -r /root/.cache
COPY config/env_dockerfile /var/interlegis/evl/.env

#RUN python3 manage.py compilescss

#RUN python3 manage.py collectstatic --noinput --clear

# Remove .env(fake) e evl.db da imagem
RUN rm -rf /var/interlegis/evl/.env && \
    rm -rf /var/interlegis/evl/evl.db

RUN chmod +x /var/interlegis/evl/start.sh && \
    chmod +x /var/interlegis/evl/busy-wait.sh && \
    chmod +x /var/interlegis/evl/gunicorn_start.sh && \
    ln -sf /proc/self/fd/1 /var/log/nginx/access.log && \
    ln -sf /proc/self/fd/1 /var/log/nginx/error.log && \
    mkdir /var/log/evl/

VOLUME ["/var/interlegis/evl/data", "/var/interlegis/evl/media"]

CMD ["/var/interlegis/evl/start.sh"]
