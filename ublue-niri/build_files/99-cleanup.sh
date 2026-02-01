#!/bin/bash

set -xeuo pipefail

# === workaround ===

systemctl enable rechunker-group-fix.service

# === remove files ===

rm -f /usr/bin/chsh
rm -rf /root/.ansible/
rm -rf /tmp/* /var/tmp/*
rm -rf /usr/lib/systemd/system/flatpak-add-fedora-repos.service
rm -rf /usr/share/doc/*

dnf clean all
rm -rf /var/cache/dnf/*

# === generate initramfs ===

KERNEL_VERSION="$(find "/usr/lib/modules" -maxdepth 1 -type d ! -path "/usr/lib/modules" -exec basename '{}' ';' | sort | tail -n 1)"
export DRACUT_NO_XATTR=1
dracut --no-hostonly --kver "$KERNEL_VERSION" --reproducible --zstd -v --add ostree -f "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"
chmod 0600 "/usr/lib/modules/${KERNEL_VERSION}/initramfs.img"
