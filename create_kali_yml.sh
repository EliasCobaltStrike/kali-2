#!/bin/bash
set -e

echo "==> Erstelle Dockerfile…"
cat > Dockerfile << 'EOF'
FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=de_DE.UTF-8
ENV LC_ALL=de_DE.UTF-8

# Ganz oben: Nur HTTP-Mirror, damit keine SSL-Fehler mehr kommen
RUN echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" > /etc/apt/sources.list

# Update + Locale + Pakete
RUN apt-get clean && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg locales supervisor \
      xfce4 xfce4-goodies x11vnc xvfb novnc websockify && \
    echo "de_DE.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && update-locale LANG=de_DE.UTF-8 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# noVNC aus GitHub (offiziell, kein Launch-Missing)
RUN mkdir -p /opt/novnc/utils && \
    curl -sL https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz \
      | tar -xzf - -C /opt/novnc --strip-components=1 && \
    curl -sL https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.tar.gz \
      | tar -xzf - -C /opt/novnc/utils --strip-components=1 && \
    chmod +x /opt/novnc/utils/novnc_proxy

# Kopiere Supervisor-Config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 6080

CMD ["/usr/bin/supervisord", "-n"]
EOF

echo "==> Erstelle supervisord.conf…"
cat > supervisord.conf << 'EOF'
[supervisord]
nodaemon=true

[program:xvfb]
command=/usr/bin/Xvfb :0 -screen 0 1280x720x16
autostart=true
autorestart=true
priority=10
stderr_logfile=/var/log/xvfb.err.log
stdout_logfile=/var/log/xvfb.out.log

[program:x11vnc]
command=/usr/bin/x11vnc -display :0 -forever -nopw -shared
autostart=true
autorestart=true
priority=20
stderr_logfile=/var/log/x11vnc.err.log
stdout_logfile=/var/log/x11vnc.out.log

[program:novnc]
command=/opt/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080
autostart=true
autorestart=true
priority=30
stderr_logfile=/var/log/novnc.err.log
stdout_logfile=/var/log/novnc.out.log
EOF

echo "==> Erstelle docker-compose.yml…"
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  kali-desktop:
    build: .
    container_name: kali-desktop
    ports:
      - "6080:6080"
    stdin_open: true
    tty: true
    restart: unless-stopped
EOF

echo "==> Baue Docker-Image…"
docker compose build --no-cache

echo "==> Starte Container…"
docker compose up -d

echo "✔︎ Kali mit XFCE + noVNC läuft jetzt auf http://localhost:6080"
