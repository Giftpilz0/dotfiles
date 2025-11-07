#!/usr/bin/env bash

# Directories to clean up
dirs=(
  "$HOME/.bashrc"
  "$HOME/.bashrc.d"
  "$HOME/.config/common"
  "$HOME/.config/eww"
  "$HOME/.config/gtk-3.0"
  "$HOME/.config/gtk-4.0"
  "$HOME/.config/helix"
  "$HOME/.config/hypr"
  "$HOME/.config/kitty"
  "$HOME/.config/matugen"
  "$HOME/.config/niri"
  "$HOME/.config/sway"
  "$HOME/.config/swaync"
  "$HOME/.config/vim"
  "$HOME/.config/wofi"
  "$HOME/.config/xdg-desktop-portal"
  "$HOME/.var/app/dev.zed.Zed/config/zed"
  "$HOME/.config/libreoffice/4/user/registrymodifications.xcu"
  "$HOME/.inputrc"
  "$HOME/.local/bin"
)

# Systemd services to enable & start
services=(
  hypridle
  hyprpolkitagent
  swaync
  hyprpaper
  ssh-agent
  sysutil-deviceapi
)

echo -e "\n======================================="
echo "Installing yolk-git from COPR repository"
echo "======================================="

# Check if we're running as root
if [[ $EUID -ne 0 ]]; then
    echo "[!] Script is not running as root, skipping package installation"
    echo "[!] Please run with 'sudo' to install packages"
else
    echo "[✔] Enabling COPR repository giftpilz0/misc"
    if dnf copr enable -y giftpilz0/misc >/dev/null 2>&1; then
        echo "[✔] COPR repository giftpilz0/misc enabled successfully"

        echo "[✔] Installing yolk-git from COPR"
        if dnf install -y yolk-git >/dev/null 2>&1; then
            echo "[✔] yolk-git installed successfully"
        else
            echo "[✘] Failed to install yolk-git"
        fi
    else
        echo "[✘] Failed to enable COPR repository giftpilz0/misc"
    fi
fi

echo -e "\n======================================="
echo "Cleaning old dotfiles directories and files"
echo "======================================="
for d in "${dirs[@]}"; do
  if [ -L "$d" ]; then
    echo "[✔] Unlinking symlink $d"
    unlink "$d"
  elif [ -d "$d" ]; then
    echo "[✔] Removing directory $d"
    rm -rf "$d"
  elif [ -f "$d" ]; then
    echo "[✔] Removing file $d"
    rm -f "$d"
  else
    echo "[✘] Skipping $d (not present or not a directory/symlink/file)"
  fi
done

echo -e "\n======================================="
echo "Running yolk sync"
echo "======================================="
if yolk sync >/dev/null 2>&1; then
  echo "[✔] yolk sync completed successfully"
else
  echo "[✘] yolk sync completed with warnings"
fi

echo -e "[✔] Listing installed packages\n"
yolk list

echo -e "\n======================================="
echo "Setting up systemd user services"
echo "======================================="
for svc in "${services[@]}"; do
  echo "[✔] Enabling & starting $svc.service"
  if systemctl --user enable --now "$svc.service" >/dev/null 2>&1; then
    echo -e "[✔] $svc.service is now running\n"
  else
    echo -e "[✘] Failed to enable/start $svc.service\n"
    exit 1
  fi
done

echo -e "\n======================================="
echo "Dotfiles installation complete"
echo "======================================="
