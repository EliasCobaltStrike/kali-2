#!/bin/bash
cat > kali.yml << 'EOF'
version: "3.8"

services:
  kali-desktop:
    image: kalilinux/kali-rolling
    container_name: kali-desktop
    ports:
      - "6080:6080"
    stdin_open: true
    tty: true
    privileged: true
    command: >
      bash -c "
      apt update && \
      apt install -y xfce4 xfce4-goodies tightvncserver novnc websockify xterm locales sudo dbus-x11 && \
      echo 'de_DE.UTF-8 UTF-8' > /etc/locale.gen && locale-gen && update-locale LANG=de_DE.UTF-8 && \
      useradd -m -s /bin/bash kali && echo 'kali:kali' | chpasswd && adduser kali sudo && \
      mkdir -p /home/kali/.vnc && \
      echo '#!/bin/sh\nxrdb $HOME/.Xresources\nstartxfce4 &' > /home/kali/.vnc/xstartup && chmod +x /home/kali/.vnc/xstartup && \
      echo 'kali' | vncpasswd -f > /home/kali/.vnc/passwd && chmod 600 /home/kali/.vnc/passwd && \
      chown -R kali:kali /home/kali/.vnc && \
      sudo -u kali vncserver :1 -geometry 1280x800 -depth 24 -localhost no && \
      ln -sf /usr/share/novnc/utils/websockify /usr/share/novnc/utils/websockify/run || true && \
      /usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080 --web /usr/share/novnc
      "
EOF

echo "Datei kali.yml wurde erstellt!"
