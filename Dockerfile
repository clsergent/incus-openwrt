# syntax=docker/dockerfile:1
ARG ALPINE_VERSION=3.24
FROM --platform=linux/arm64 alpine:${ALPINE_VERSION}

WORKDIR /build
COPY targets/ /config/targets/
COPY scripts/ /scripts/
COPY build.sh /scripts/build.sh
COPY incus.initd /build/incus.initd
RUN chmod +x /scripts/*.sh /scripts/build.sh

ENTRYPOINT ["/scripts/build.sh"]
VOLUME ["/output"]
