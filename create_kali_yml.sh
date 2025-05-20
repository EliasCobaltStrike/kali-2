#!/bin/bash

set -e

echo "==> Erstelle Dockerfile für Kali Linux Desktop mit XFCE und noVNC..."

cat > Dockerfile <<'EOF'
FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=de_DE.UTF-8
ENV LC_ALL=de_DE.UTF-8

# Kali mirror setzen (vertrauenswürdiger und schnell)
RUN echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" > /etc/apt/sources.list

# CA Zertifikate und SSL-Probleme fixen, apt immer updaten, Update erzwingen
RUN apt-get clean && \
    apt-get update --allow-insecure-repositories --allow-unauthenticated || true && \
    apt-get install -y --no-install-recommends ca-certificates apt-transport-https curl gnupg && \
    update-ca-certificates --fresh && \
    apt-get update --fix-missing && \
    apt-get upgrade -y --fix-missing && \
    apt-get dist-upgrade -y --fix-missing

# Pakete installieren - XFCE Desktop, noVNC, Supervisor etc.
RUN apt-get install -y --no-install-recommends \
    xfce4 xfce4-goodies x11vnc xvfb novnc supervisor curl locales && \
    locale-gen de_DE.UTF-8 && update-locale LANG=de_DE.UTF-8 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# noVNC manuell herunterladen und entpacken
RUN mkdir -p /opt/novnc && \
    curl -L https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar -xzf - -C /opt/novnc --strip-components=1 && \
    curl -L https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.tar.gz | tar -xzf - -C /opt/novnc/utils --strip-components=1 && \
    chmod +x /opt/novnc/utils/novnc_proxy

# Benutzer kali anlegen mit Passwort kali
RUN useradd -m -s /bin/bash kali && echo "kali:kali" | chpasswd && adduser kali sudo

# Supervisor Config hinzufügen
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 5900 6080

CMD ["/usr/bin/supervisord", "-n"]
EOF

echo "==> Erstelle Supervisord-Konfiguration..."

cat > supervisord.conf <<'EOF'
[supervisord]
nodaemon=true

[program:xvfb]
command=/usr/bin/Xvfb :0 -screen 0 1280x720x16
autorestart=true
priority=10
stdout_logfile=/var/log/xvfb.log
stderr_logfile=/var/log/xvfb.err.log

[program:x11vnc]
command=/usr/bin/x11vnc -display :0 -forever -nopw -shared
autorestart=true
priority=20
stdout_logfile=/var/log/x11vnc.log
stderr_logfile=/var/log/x11vnc.err.log

[program:novnc]
command=/opt/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080
autorestart=true
priority=30
stdout_logfile=/var/log/novnc.log
stderr_logfile=/var/log/novnc.err.log
EOF

echo "==> Erstelle docker-compose.yml..."

cat > docker-compose.yml <<'EOF'
version: "3.8"

services:
  kali-desktop:
    build: .
    container_name: kali-desktop
    ports:
      - "6080:6080"
      - "5900:5900"
    stdin_open: true
    tty: true
EOF

echo "==> Baue Docker-Image..."
docker compose build

echo "==> Starte Container..."
docker compose up
