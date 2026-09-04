# https://developers.home-assistant.io/docs/add-ons/configuration#add-on-dockerfile
FROM ghcr.io/maziggy/bambuddy:daily AS builder
FROM ghcr.io/home-assistant/base-python:3.14-alpine3.23

LABEL org.opencontainers.image.title="Home Assistant Add-on: Bambuddy add-on (DAILY)"
LABEL org.opencontainers.image.description="A powerful, self-hosted command center for Bambu Lab — from one A1 to an entire print farm. Your Printers. No Cloud. Your Rules."
LABEL org.opencontainers.image.source="https://github.com/Spegeli/homeassistant-app-bambuddy"
LABEL org.opencontainers.image.licenses="MIT License"

WORKDIR /app

# Install system dependencies
# iproute2 replaces the BusyBox `ip` applet, which does not support `-j`.
# Without it network interface detection silently falls back to a path that
# cannot see IP aliases, so virtual printers cannot be bound to them.
RUN apk add --no-cache \
  build-base \
  ca-certificates \
  py3-opencv \
  curl \
  ffmpeg \
  iproute2

# Install Python dependencies with cache mount
COPY --from=builder /app/requirements.txt ./
RUN sed -i 's/opencv-python-headless/# opencv-python-headless/' /app/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install --root-user-action=ignore -r requirements.txt

COPY --from=builder /app /app

ENV PYTHONUNBUFFERED=1
ENV DATA_DIR=/app/data
ENV LOG_DIR=/app/logs

# Copy root filesystem
COPY rootfs /
RUN chmod a+x /etc/services.d/bambuddy/run /etc/services.d/bambuddy/finish
