[group('Fonts')]
fonts-setup:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    elevate

    header_box "Font Setup"

    CHOICE=$(show_menu "Font Action" \
        "Install Maple Mono fonts" \
        "Remove Maple Mono fonts" \
        "Cancel")

    case "$CHOICE" in
        "Install Maple Mono fonts")
            ujust _fonts-install
            ;;
        "Remove Maple Mono fonts")
            ujust _fonts-remove
            ;;
        *)
            log_info "Cancelled"
            ;;
    esac

[private]
_fonts-install:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"

    info_box "Installing Maple Mono Fonts"

    if are_maple_fonts_installed; then
        success_box "Maple Mono fonts are already installed"
        if ! gum confirm "Reinstall anyway?"; then
            exit 0
        fi
    fi

    FONT_DIR="/usr/share/fonts"
    mkdir -p "${FONT_DIR}/Maple Mono Variable"
    mkdir -p "${FONT_DIR}/Maple Mono NF"

    log_info "Downloading Maple Mono Variable..."
    TMPDIR=$(mktemp -d)
    trap "rm -rf $TMPDIR" EXIT

    LATEST_URL=$(curl -fsSL --retry 3 \
        "https://api.github.com/repos/subframe7536/maple-font/releases/latest" | \
        jq -r '.assets[] | select(.name == "MapleMono-Variable.zip") | .browser_download_url')

    if [[ -z "$LATEST_URL" || "$LATEST_URL" == "null" ]]; then
        error_box "Could not find Maple Mono Variable download URL"
        exit 1
    fi

    curl -fsSL --retry 3 -o "${TMPDIR}/maple-variable.zip" "$LATEST_URL"
    unzip -oq "${TMPDIR}/maple-variable.zip" -d "${FONT_DIR}/Maple Mono Variable"
    log_info "Maple Mono Variable installed"

    log_info "Downloading Maple Mono NF..."
    NF_URL=$(curl -fsSL --retry 3 \
        "https://api.github.com/repos/subframe7536/maple-font/releases/latest" | \
        jq -r '.assets[] | select(.name == "MapleMono-NF.zip") | .browser_download_url')

    if [[ -z "$NF_URL" || "$NF_URL" == "null" ]]; then
        error_box "Could not find Maple Mono NF download URL"
        exit 1
    fi

    curl -fsSL --retry 3 -o "${TMPDIR}/maple-nf.zip" "$NF_URL"
    unzip -oq "${TMPDIR}/maple-nf.zip" -d "${FONT_DIR}/Maple Mono NF"
    log_info "Maple Mono NF installed"

    log_info "Updating font cache..."
    fc-cache --force --system-only

    success_box "Maple Mono fonts installed successfully"

[private]
_fonts-remove:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"

    info_box "Removing Maple Mono Fonts"

    FONT_DIR="/usr/share/fonts"

    if [[ -d "${FONT_DIR}/Maple Mono Variable" ]]; then
        rm -rf "${FONT_DIR}/Maple Mono Variable"
        log_info "Removed: Maple Mono Variable"
    fi

    if [[ -d "${FONT_DIR}/Maple Mono NF" ]]; then
        rm -rf "${FONT_DIR}/Maple Mono NF"
        log_info "Removed: Maple Mono NF"
    fi

    fc-cache --force --system-only

    success_box "Maple Mono fonts removed"

[group('Fonts')]
fonts-status:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    elevate

    header_box "Font Status"

    if are_maple_fonts_installed; then
        echo "  ✔ Maple Mono installed"
    else
        echo "  ✘ Maple Mono not installed"
    fi

    echo ""
    info_box "Font Directories"
    for dir in /usr/share/fonts/Maple*; do
        if [[ -d "$dir" ]]; then
            echo "  ✔ $dir"
        fi
    done
