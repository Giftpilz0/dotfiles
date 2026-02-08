[group('System')]
update:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    if ! is_root; then
        if request_root "System update requires root privileges"; then
            exec sudo ujust update
        fi
        exit 0
    fi

    show_header "Updating System"

    if command -v bootc &>/dev/null && [[ -f /run/ostree-booted ]]; then
        log_info "Detected bootc system"
        bootc upgrade
    elif command -v dnf &>/dev/null; then
        log_info "Detected dnf-based system"
        dnf upgrade -y
    else
        log_error "No supported package manager found"
        exit 1
    fi

    if command -v flatpak &>/dev/null; then
        echo ""
        if flatpak remotes 2>/dev/null | grep -q system; then
            log_info "Updating system flatpaks..."
            flatpak update -y 2>/dev/null || true
        fi
        if flatpak remotes 2>/dev/null | grep -q user; then
            log_info "Updating user flatpaks..."
            flatpak update --user -y 2>/dev/null || true
        fi
    fi

    show_success "System update complete"

[group('System')]
toggle-auto-update:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    if ! is_root; then
        if request_root "Modifying auto-update requires root privileges"; then
            exec sudo ujust toggle-auto-update
        fi
        exit 0
    fi

    show_header "Automatic Updates"

    CURRENT_STATE="disabled"
    if systemctl is-enabled -q uupd.timer 2>/dev/null; then
        CURRENT_STATE="enabled"
    elif systemctl is-enabled -q dnf5-automatic.timer 2>/dev/null; then
        CURRENT_STATE="enabled"
    fi

    echo "Current state: $CURRENT_STATE"
    echo ""

    ACTION=$(gum choose --header="Toggle automatic updates?" "Enable" "Disable" "Cancel")
    [[ "$ACTION" == "Cancel" || -z "$ACTION" ]] && exit 0

    TIMER=""
    if systemctl cat -- uupd.timer &>/dev/null; then
        TIMER="uupd.timer"
    elif systemctl cat -- dnf-automatic.timer &>/dev/null; then
        TIMER="dnf-automatic.timer"
    else
        log_warn "No automatic update timer found"
        exit 1
    fi

    log_info "Using timer: $TIMER"

    if [[ "$ACTION" == "Enable" ]]; then
        systemctl enable "$TIMER" &>/dev/null
        systemctl start "$TIMER" &>/dev/null
        log_info "Automatic updates enabled"
    elif [[ "$ACTION" == "Disable" ]]; then
        systemctl disable "$TIMER" &>/dev/null
        systemctl stop "$TIMER" &>/dev/null
        log_info "Automatic updates disabled"
    fi
