#!/bin/bash

set -e

echo "==> Erstelle Dockerfile für Kali Linux Desktop mit XFCE und noVNC..."

cat > Dockerfile <<EOF
FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=de_DE.UTF-8
ENV LANGUAGE=de_DE:de
ENV LC_ALL=de_DE.UTF-8

# Zertifikate fixen & lokale Mirror nutzen
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg locales \
    && locale-gen de_DE.UTF-8 && update-locale LANG=de_DE.UTF-8 \
    && echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" > /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    xfce4 xfce4-goodies x11vnc xvfb novnc supervisor \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# noVNC Setup
RUN mkdir -p /opt/novnc/utils/websockify \
    && curl -sL https://github.com/novnc/noVNC/archive/refs/heads/master.tar.gz | tar -xz -C /opt \
    && mv /opt/noVNC-master /opt/novnc \
    && curl -sL https://github.com/novnc/websockify/archive/refs/heads/master.tar.gz | tar -xz -C /opt/novnc/utils \
    && mv /opt/novnc/utils/websockify-master /opt/novnc/utils/websockify

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 6080
CMD ["/usr/bin/supervisord"]
EOF

echo "==> Erstelle Supervisord-Konfiguration..."

cat > supervisord.conf <<EOF
[supervisord]
nodaemon=true

[program:x11vnc]
command=x11vnc -forever -usepw -create
priority=10
autostart=true
autorestart=true

[program:novnc]
command=/opt/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080
priority=20
autostart=true
autorestart=true
EOF

echo "==> Erstelle docker-compose.yml..."

cat > docker-compose.yml <<EOF
services:
  kali-desktop:
    build: .
    ports:
      - "6080:6080"
    container_name: kali-desktop
    restart: unless-stopped
EOF

echo "==> Starte Docker Build..."

docker-compose build

echo "✅ Fertig! Starte mit: docker-compose up -d"
