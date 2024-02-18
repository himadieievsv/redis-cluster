FROM alpine:latest

LABEL maintainer="Serhii Himadieiev <gimadeevsv@gmail.com>"

# Some Environment Variables
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Install system dependencies
RUN apk update \
    && apk add --no-cache wget tar gcc make g++ alpine-sdk libc6-compat linux-headers tcl

# Ensure UTF-8 lang and locale
ENV LANG       "C.UTF-8"
ENV LANGUAGE   "C.UTF-8"
ENV LC_ALL     "C.UTF-8"

ARG redis_version=7.2

RUN wget --no-check-certificate -qO redis.tar.gz https://github.com/redis/redis/tarball/${redis_version} \
    && tar xfz redis.tar.gz -C / \
    && mv /redis-* /redis \
    && rm redis.tar.gz

RUN (mkdir /redis-build && cd /redis && make PREFIX=/redis-build install)

FROM alpine:latest

RUN apk update && \
    apk add runit && \
    apk cache clean

RUN mkdir /redis-conf /redis-data /etc/supervisor/ /var/log/supervisor
COPY redis-cluster.tmpl /redis-conf/redis-cluster.tmpl
COPY redis.tmpl         /redis-conf/redis.tmpl
COPY sentinel.tmpl      /redis-conf/sentinel.tmpl
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY run-servers.sh /run-servers.sh
COPY --from=0 /redis-build/* /usr/local/bin/

RUN chmod 755 /docker-entrypoint.sh \
    && chmod 755 /run-servers.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["redis-cluster"]
