FROM golang:1.13.7-alpine as build

WORKDIR /go/src/github.com/DNSCrypt/dnscrypt-proxy/

ARG BUILD_VERSION=2.0.45

ARG ARCHIVE_URL=https://github.com/DNSCrypt/dnscrypt-proxy/archive/

ENV CGO_ENABLED 0
RUN apk add --no-cache libcap

RUN test -n "${BUILD_VERSION}" \
	&& apk add --no-cache ca-certificates=20191127-r0 curl=7.67.0-r3 \
	&& curl -L "${ARCHIVE_URL}${BUILD_VERSION}.tar.gz" -o /tmp/dnscrypt-proxy.tar.gz \
	&& tar xzf /tmp/dnscrypt-proxy.tar.gz --strip 1 -C /go/src/github.com/DNSCrypt \
	&& go build -v -ldflags="-s -w" -o /app

WORKDIR /config

RUN cp -a /go/src/github.com/DNSCrypt/dnscrypt-proxy/example-* ./

COPY dnscrypt-proxy.toml ./
RUN setcap 'cap_net_bind_service=+eip' /app

# ----------------------------------------------------------------------------

FROM scratch

LABEL org.opencontainers.image.authors "Kyle Harding <https://klutchell.dev>"
LABEL org.opencontainers.image.url "https://github.com/klutchell/dnscrypt-proxy"
LABEL org.opencontainers.image.documentation "https://github.com/klutchell/dnscrypt-proxy"
LABEL org.opencontainers.image.source "https://github.com/klutchell/dnscrypt-proxy"
LABEL org.opencontainers.image.title "klutchell/dnscrypt-proxy"
LABEL org.opencontainers.image.description "dnscrypt-proxy is a flexible DNS proxy, with support for encrypted DNS protocols"

COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=build --chown=nobody:nogroup /app /app
COPY --from=build --chown=nobody:nogroup /config /config

USER nobody

ENTRYPOINT ["/app", "-config", "/config/dnscrypt-proxy.toml"]
RUN ["/app", "-version"]
