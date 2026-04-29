# https://developers.home-assistant.io/docs/add-ons/configuration#add-on-dockerfile
ARG BAMBUDDY_VERSION
ARG BUILD_FROM

FROM ghcr.io/maziggy/bambuddy:${BAMBUDDY_VERSION} as builder
FROM $BUILD_FROM

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
