# Targets:
#   slim - tac_plus + spawnd only, no Perl (no LDAP/external-script Mavis backends)
#   full - slim + Perl with LDAP/SSL modules (default, last stage)
#
#   docker build --target slim -t tac_plus:alpine-slim .
#   docker build -t tac_plus:alpine .
#
# Multi-arch (amd64 + arm64):
#   docker buildx build --platform linux/amd64,linux/arm64 --target slim \
#       -t <registry>/tacacs_plus:alpine-slim --push .

ARG ALPINE_VERSION=3.24

# Compile tac_plus
FROM alpine:${ALPINE_VERSION} AS build

# Commit of https://github.com/MarcJHuber/event-driven-servers and the sha256
# of its GitHub source archive. Override with --build-arg to update.
ARG SRC_VERSION=c10b425e754099b77920c2efbb899bdcd94ca57e
ARG SRC_HASH=055403f237af72b8bc3f510b562a22e48017db957d6a917f30422445c850456c

ADD https://github.com/MarcJHuber/event-driven-servers/archive/$SRC_VERSION.tar.gz /tac_plus.tar.gz

RUN echo "${SRC_HASH}  /tac_plus.tar.gz" | sha256sum -c -

RUN apk add --no-cache build-base bzip2 perl perl-digest-md5 perl-ldap perl-io-socket-ssl bash \
        pcre2-dev c-ares-dev openssl-dev linux-headers && \
    tar -xzf /tac_plus.tar.gz && \
    cd /event-driven-servers-$SRC_VERSION && \
    ./configure --prefix=/tacacs && \
    env SHELL=/bin/bash make && \
    env SHELL=/bin/bash make install

# Minimal runtime
FROM alpine:${ALPINE_VERSION} AS slim

LABEL org.opencontainers.image.title="tac_plus"
LABEL org.opencontainers.image.description="TACACS+ server (tac_plus) used by VyOS smoketests"

COPY --from=build /tacacs /tacacs
COPY tac_plus.sample.cfg /etc/tac_plus/tac_plus.cfg
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN apk add --no-cache pcre2 c-ares libssl3

EXPOSE 49

ENTRYPOINT ["/docker-entrypoint.sh"]

# Full runtime (default last stage)
FROM slim AS full

RUN apk add --no-cache perl perl-digest-md5 perl-ldap perl-io-socket-ssl
