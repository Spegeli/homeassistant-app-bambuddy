# https://developers.home-assistant.io/docs/add-ons/configuration#add-on-dockerfile
ARG BAMBUDDY_VERSION=0.2.3.2

FROM ghcr.io/maziggy/bambuddy:${BAMBUDDY_VERSION} AS builder
FROM ghcr.io/home-assistant/base-python:3.14-alpine3.23

LABEL org.opencontainers.image.title="Home Assistant Add-on: Bambuddy add-on (STABLE)"
LABEL org.opencontainers.image.description="A powerful, self-hosted command center for Bambu Lab — from one A1 to a 40-printer farm. Your Printers. No Cloud. Your Rules."
LABEL org.opencontainers.image.source="https://github.com/Spegeli/homeassistant-app-bambuddy"
LABEL org.opencontainers.image.licenses="MIT License"

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
  build-base \
  py3-opencv \
  curl \
  ffmpeg

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
