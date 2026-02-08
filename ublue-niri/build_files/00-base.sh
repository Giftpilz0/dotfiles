#!/bin/bash

set -xeuo pipefail

# === enable dnf cache ===
dnf -y install 'dnf5-command(config-manager)'
dnf config-manager setopt keepcache=1

# === install deps ===
dnf5 install -y \
    ansible \
    curl \
    git-core \
    gum \
    jq \
    just \
    python3-dnf \
    python3-rpm \
    tar

# === ansible ===
cd /ctx && just ansible-bootstrap

# === disable dnf cache ===
dnf config-manager setopt keepcache=0

# === upgrade parameters ===
sed -i 's|#AutomaticUpdatePolicy.*|AutomaticUpdatePolicy=stage|' /etc/rpm-ostreed.conf
sed -i 's|#LockLayering.*|LockLayering=true|' /etc/rpm-ostreed.conf
sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bootc update --quiet|' /usr/lib/systemd/system/bootc-fetch-apply-updates.service
sed -i 's|^OnUnitInactiveSec=.*|OnUnitInactiveSec=7d\nPersistent=true|' /usr/lib/systemd/system/bootc-fetch-apply-updates.timer

# === services ===
systemctl enable --global gnome-keyring-daemon.service
systemctl enable --global gnome-keyring-daemon.socket
systemctl enable systemd-timesyncd.service
systemctl mask systemd-remount-fs.service

systemctl enable bootc-fetch-apply-updates.timer
systemctl enable uupd.timer
