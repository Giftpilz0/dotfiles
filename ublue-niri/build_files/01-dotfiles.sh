#!/bin/bash

set -xeuo pipefail

# === install file overides ===

install -d /usr/share/ublue-niri/
cp -avf "/ctx/files"/. /

# === setup dotfiles ===

git clone "https://github.com/Giftpilz0/dotfiles.git" /usr/share/ublue-niri/yolk/

systemctl enable --global yolk-init.service
systemctl preset --global yolk-init.service
systemctl enable yolk-init-root.service
systemctl preset yolk-init-root.service

# === install fonts ===

mkdir -p "/usr/share/fonts/Maple Mono"

MAPLE_TMPDIR="$(mktemp -d)"
LATEST_RELEASE_FONT="$(curl --retry 3 "https://api.github.com/repos/subframe7536/maple-font/releases/latest" | jq '.assets[] | select(.name == "MapleMono-Variable.zip") | .browser_download_url' -rc)"
curl --retry 3 -fSsLo "${MAPLE_TMPDIR}/maple.zip" "${LATEST_RELEASE_FONT}"
unzip "${MAPLE_TMPDIR}/maple.zip" -d "/usr/share/fonts/Maple Mono"
rm -rf "${MAPLE_TMPDIR}"

MAPLE_NF_TMPDIR="$(mktemp -d)"
LATEST_RELEASE_FONT="$(curl --retry 3 "https://api.github.com/repos/subframe7536/maple-font/releases/latest" | jq '.assets[] | select(.name == "MapleMono-NF.zip") | .browser_download_url' -rc)"
curl --retry 3 -fSsLo "${MAPLE_NF_TMPDIR}/maple.zip" "${LATEST_RELEASE_FONT}"
unzip "${MAPLE_NF_TMPDIR}/maple.zip" -d "/usr/share/fonts/Maple Mono NF"
rm -rf "${MAPLE_NF_TMPDIR}"

fc-cache --force --really-force --system-only --verbose

# === misc ===

echo "application/vnd.flatpak.ref=io.github.kolunmi.Bazaar.desktop" >> /usr/share/applications/mimeapps.list

install -d /usr/share/bash-completion/completions /usr/share/zsh/site-functions /usr/share/fish/vendor_completions.d/
just --completions bash | sed -E 's/([\(_" ])just/\1ujust/g' > /usr/share/bash-completion/completions/ujust
just --completions zsh | sed -E 's/([\(_" ])just/\1ujust/g' > /usr/share/zsh/site-functions/_ujust
just --completions fish | sed -E 's/([\(_" ])just/\1ujust/g' > /usr/share/fish/vendor_completions.d/ujust.fish
