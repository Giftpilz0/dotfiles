[group('System')]
toggle-auto-update:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    elevate

    header_box "Automatic Updates"

    CURRENT_STATE="disabled"
    if systemctl is-enabled -q uupd.timer 2>/dev/null; then
        CURRENT_STATE="enabled"
    elif systemctl is-enabled -q dnf5-automatic.timer 2>/dev/null; then
        CURRENT_STATE="enabled"
    fi

    info_box "Current state: $CURRENT_STATE"

    ACTION=$(show_menu "Toggle automatic updates?" "Enable" "Disable" "Cancel")
    [[ "$ACTION" == "Cancel" || -z "$ACTION" ]] && exit 0

    TIMER=""
    if systemctl cat -- uupd.timer &>/dev/null; then
        TIMER="uupd.timer"
    elif systemctl cat -- dnf-automatic.timer &>/dev/null; then
        TIMER="dnf-automatic.timer"
    else
        warn_box "No automatic update timer found"
        exit 1
    fi

    log_info "Using timer: $TIMER"

    if [[ "$ACTION" == "Enable" ]]; then
        systemctl enable "$TIMER" &>/dev/null
        systemctl start "$TIMER" &>/dev/null
        success_box "Automatic updates enabled"
    elif [[ "$ACTION" == "Disable" ]]; then
        systemctl disable "$TIMER" &>/dev/null
        systemctl stop "$TIMER" &>/dev/null
        success_box "Automatic updates disabled"
    fi
