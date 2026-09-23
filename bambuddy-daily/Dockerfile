# https://developers.home-assistant.io/docs/apps/configuration/#app-dockerfile
#
# Runtime = the upstream image itself (Debian, python 3.13-slim, multi-arch),
# with s6-overlay v3 + bashio layered on. Avoids re-installing upstream's
# requirements on Alpine and swapping opencv (which broke plate detection —
# see the STABLE Dockerfile for the full explanation). OpenCV already works
# on the upstream image.
#
# Daily tracks the rolling upstream :daily tag, so there is no version ARG
# before FROM; BAMBUDDY_VERSION is only used for the io.hass.version label.
FROM ghcr.io/maziggy/bambuddy:daily

# All build-args in one place. S6_OVERLAY_VERSION and BASHIO_VERSION are pinned
# here and bumped by hand; BAMBUDDY_VERSION and BUILD_ARCH come from the build
# workflow (BAMBUDDY_VERSION only feeds the io.hass.version label here).
# TARGETARCH is set by buildx.
ARG S6_OVERLAY_VERSION=3.2.0.2
ARG BASHIO_VERSION=v0.16.2
ARG TARGETARCH
ARG BAMBUDDY_VERSION
ARG BUILD_ARCH

LABEL org.opencontainers.image.title="Home Assistant App: Bambuddy (Daily)"
LABEL org.opencontainers.image.description="A powerful, self-hosted command center for Bambu Lab — from one A1 to an entire print farm. Your Printers. No Cloud. Your Rules."
LABEL org.opencontainers.image.source="https://github.com/Spegeli/homeassistant-app-bambuddy"
LABEL org.opencontainers.image.licenses="MIT AND AGPL-3.0-only"

# Supervisor metadata (required when not using the HA builder). It reads
# io.hass.version as the installed image version.
LABEL io.hass.version="${BAMBUDDY_VERSION}"
LABEL io.hass.type="app"
LABEL io.hass.arch="${BUILD_ARCH}"

WORKDIR /app

# jq + xz-utils bootstrap s6-overlay and bashio; iproute2 gives the real `ip`
# (BusyBox's has no -j) so virtual printers can bind IP aliases. curl and
# ca-certificates are already in the upstream image. jq stays at runtime too,
# bashio reads the app options through it.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        jq \
        xz-utils \
        iproute2 \
    && rm -rf /var/lib/apt/lists/*

# s6-overlay v3, the supervision layer every HA app runs under. The last step
# links with-contenv: s6 v3 installs it at /command/with-contenv, but the
# shebang "#!/usr/bin/with-contenv bashio" expects it at /usr/bin.
RUN set -eux; \
    case "${TARGETARCH:-amd64}" in \
        amd64) S6_ARCH=x86_64 ;; \
        arm64) S6_ARCH=aarch64 ;; \
        *)     echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" | tar -Jxpf - -C /; \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" | tar -Jxpf - -C /; \
    ln -s /command/with-contenv /usr/bin/with-contenv

# bashio, the HA helper the run script reads its options with
RUN set -eux; \
    mkdir -p /tmp/bashio; \
    curl -fsSL "https://github.com/hassio-addons/bashio/archive/${BASHIO_VERSION}.tar.gz" | tar -xzf - --strip-components=1 -C /tmp/bashio; \
    mv /tmp/bashio/lib /usr/lib/bashio; \
    ln -s /usr/lib/bashio/bashio /usr/bin/bashio; \
    rm -rf /tmp/bashio

# Fallback only - the run script exports the same values at startup.
ENV PYTHONUNBUFFERED=1 \
    DATA_DIR=/config/data \
    LOG_DIR=/config/logs

# s6 service definition (run + finish), copied executable in one step.
# Deliberately scoped to this one directory instead of "COPY rootfs /": --chmod
# also applies to the directories along the path. Add a line here if rootfs
# ever gains another path.
COPY --chmod=755 rootfs/etc/services.d/bambuddy /etc/services.d/bambuddy

# Upstream ships its own ENTRYPOINT (PUID/PGID + gosu drop) and a CMD that
# starts uvicorn. Replace the entrypoint with s6's /init and blank CMD, else
# s6 stage 2 runs the inherited CMD as a second uvicorn on port 8000.
ENTRYPOINT ["/init"]
CMD []
