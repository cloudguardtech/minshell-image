FROM alpine:3.6

MAINTAINER "CloudGuard Technologies LLC"
LABEL org.label-schema.schema-version="1.0.0-rc.1"
LABEL org.label-schema.name="Minimum Alpine Shell Tools"
LABEL org.label-schema.description="A minimum Alpine Container Image to work as a sidecar or initialization container for Kubernetes applications"
LABEL org.label-schema.vendor="CloudGuard Technologies LLC"

RUN apk add --no-cache \
  bash \
  curl \
  jq \
  openssl

RUN mkdir -p /home/app \
  && addgroup -S app \
  && adduser -S -G app -h /home/app -D app

ENV HOME=/home/app

USER app
WORKDIR $HOME
