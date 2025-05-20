#!/bin/bash
cat > kali.yml << 'EOF'
version: '3.8'

services:
  kali-desktop:
    image: kalilinux/kali-rolling
    container_name: kali-desktop
    ports:
      - "6080:6080"
    privileged: true
    stdin_open: true
    tty: true
    environment:
      LANG: de_DE.UTF-8
      LANGUAGE: de_DE:de
      LC_ALL: de_DE.UTF-8
      USER: kali
      PASSWORD: kali
    volumes:
      - ./kali-home:/home/kali
    command: >
      bash -c "
        apt update && \
        DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
          xfce4 xfce4-goodies tightvncserver novnc websockify xterm wget curl locales keyboard-configuration dbus-x11 sudo && \
        echo 'de_DE.UTF-8 UTF-8' > /etc/locale.gen && \
        locale-gen && \
        update-locale LANG=de_DE.UTF-8 && \
        useradd -m -s /bin/bash kali && \
        echo 'kali:kali' | chpasswd && \
        adduser kali sudo && \
        mkdir -p /home/kali/.vnc && \
        echo '#!/bin/sh\nxrdb $HOME/.Xresources\nstartxfce4 &' > /home/kali/.vnc/xstartup && \
        chmod +x /home/kali/.vnc/xstartup && \
        echo 'kali' | vncpasswd -f > /home/kali/.vnc/passwd && \
        chmod 600 /home/kali/.vnc/passwd && \
        vncserver :1 -geometry 1280x800 -depth 24 -localhost no && \
        ln -sf /usr/share/novnc/utils/websockify /usr/share/novnc/utils/websockify/run || true && \
        /usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080 --web /usr/share/novnc
      "
EOF

echo "Datei kali.yml wurde erstellt!"
