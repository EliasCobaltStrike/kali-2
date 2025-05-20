#!/bin/bash

set -e

echo "Erstelle Dockerfile..."
cat > Dockerfile <<'EOF'
FROM kalilinux/kali-rolling

# Umgebung auf Deutsch einstellen
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=de_DE.UTF-8
ENV LC_ALL=de_DE.UTF-8

# Update und Installation aller benötigten Pakete
RUN apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y && apt-get install -y --no-install-recommends \
    xfce4 xfce4-goodies x11vnc xvfb novnc supervisor curl ca-certificates locales && \
    locale-gen de_DE.UTF-8 && update-locale LANG=de_DE.UTF-8 && \
    update-ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# noVNC herunterladen und konfigurieren
RUN mkdir -p /opt/novnc && \
    curl -L https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar -xzf - -C /opt/novnc --strip-components=1 && \
    curl -L https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.tar.gz | tar -xzf - -C /opt/novnc/utils --strip-components=1 && \
    chmod +x /opt/novnc/utils/novnc_proxy

# Kali User anlegen mit Passwort "kali"
RUN useradd -m -s /bin/bash kali && echo "kali:kali" | chpasswd && adduser kali sudo

# Supervisord Konfigurationsdatei einbinden
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Ports für VNC und noVNC freigeben
EXPOSE 5900 6080

# Supervisord starten, damit alle Dienste laufen
CMD ["/usr/bin/supervisord", "-n"]
EOF

echo "Erstelle Supervisord-Konfiguration..."
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

echo "Erstelle docker-compose.yml..."
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

echo "Baue das Docker-Image..."
docker compose build

echo "Starte den Container..."
docker compose up
