# https://developers.home-assistant.io/docs/add-ons/configuration#add-on-dockerfile
#
# Runtime = the upstream image itself (Debian, python 3.13-slim, multi-arch),
# with s6-overlay v3 + bashio layered on. Avoids re-installing upstream's
# requirements on Alpine and swapping opencv (which broke plate detection —
# see the STABLE Dockerfile for the full explanation). OpenCV already works
# on the upstream image.
#
# Daily tracks the rolling upstream :daily tag (no version ARG).
FROM ghcr.io/maziggy/bambuddy:daily

ARG S6_OVERLAY_VERSION=3.2.0.2
ARG BASHIO_VERSION=v0.16.2
ARG TARGETARCH

LABEL org.opencontainers.image.title="Home Assistant Add-on: Bambuddy add-on (DAILY)"
LABEL org.opencontainers.image.description="A powerful, self-hosted command center for Bambu Lab — from one A1 to an entire print farm. Your Printers. No Cloud. Your Rules."
LABEL org.opencontainers.image.source="https://github.com/Spegeli/homeassistant-app-bambuddy"
LABEL org.opencontainers.image.licenses="MIT AND AGPL-3.0-only"

WORKDIR /app

# jq + xz-utils bootstrap s6-overlay and bashio; iproute2 gives the real `ip`
# (BusyBox's has no -j) so virtual printers can bind IP aliases. curl and
# ca-certificates are already in the upstream image. jq also stays for runtime
# (bashio reads config through it, and the run script uses it for the TZ lookup).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        jq \
        xz-utils \
        iproute2 \
    && rm -rf /var/lib/apt/lists/*

# s6-overlay v3 (the HA add-on supervision layer)
RUN set -eux; \
    case "${TARGETARCH:-amd64}" in \
        amd64) S6_ARCH=x86_64 ;; \
        arm64) S6_ARCH=aarch64 ;; \
        *)     S6_ARCH=x86_64 ;; \
    esac; \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" | tar -Jxpf - -C /; \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" | tar -Jxpf - -C /

# bashio (HA add-on config helper used by the s6 run script)
RUN set -eux; \
    mkdir -p /tmp/bashio; \
    curl -fsSL "https://github.com/hassio-addons/bashio/archive/${BASHIO_VERSION}.tar.gz" | tar -xzf - --strip-components=1 -C /tmp/bashio; \
    mv /tmp/bashio/lib /usr/lib/bashio; \
    ln -s /usr/lib/bashio/bashio /usr/bin/bashio; \
    rm -rf /tmp/bashio

# s6 v3 installs with-contenv at /command/with-contenv, but the HA add-on
# shebang "#!/usr/bin/with-contenv bashio" expects it at /usr/bin/with-contenv.
RUN ln -s /command/with-contenv /usr/bin/with-contenv

ENV PYTHONUNBUFFERED=1
ENV DATA_DIR=/config/data
ENV LOG_DIR=/config/logs

# HA add-on s6 service plumbing
COPY rootfs /
RUN chmod +x /etc/services.d/bambuddy/run /etc/services.d/bambuddy/finish

# Upstream ships its own ENTRYPOINT (PUID/PGID + gosu drop) and a CMD that
# starts uvicorn. Replace the entrypoint with s6's /init and blank CMD, else
# s6 stage 2 runs the inherited CMD as a second uvicorn on port 8000.
ENTRYPOINT ["/init"]
CMD []
