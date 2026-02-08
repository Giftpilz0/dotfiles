[group('Fonts')]
fonts-setup:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    show_header "Font Setup"

    CHOICE=$(gum choose --header="Font Action" \
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
    source "/usr/share/ujust/just/lib/common.sh"

    if ! is_root; then
        if request_root "Font installation requires root privileges"; then
            exec sudo ujust _fonts-install
        fi
        exit 0
    fi

    show_header "Installing Maple Mono Fonts"

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
        log_error "Could not find Maple Mono Variable download URL"
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
        log_error "Could not find Maple Mono NF download URL"
        exit 1
    fi

    curl -fsSL --retry 3 -o "${TMPDIR}/maple-nf.zip" "$NF_URL"
    unzip -oq "${TMPDIR}/maple-nf.zip" -d "${FONT_DIR}/Maple Mono NF"
    log_info "Maple Mono NF installed"

    log_info "Updating font cache..."
    fc-cache --force --system-only

    show_success "Maple Mono fonts installed successfully"

[private]
_fonts-remove:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    if ! is_root; then
        if request_root "Removing fonts requires root privileges"; then
            exec sudo ujust _fonts-remove
        fi
        exit 0
    fi

    show_header "Removing Maple Mono Fonts"

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

    show_success "Maple Mono fonts removed"

[group('Fonts')]
fonts-status:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    show_header "Font Status"

    if fc-list : family | grep -qi maple; then
        printf "  [✔] %-20s installed\n" "Maple Mono"
    else
        printf "  [✘] %-20s not installed\n" "Maple Mono"
    fi

    echo ""
    echo "=== Font Directories ==="
    for dir in /usr/share/fonts/Maple*; do
        if [[ -d "$dir" ]]; then
            printf "  [✔] %s\n" "$dir"
        fi
    done
