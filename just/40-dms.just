[group('DMS')]
dms-setup:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    elevate

    header_box "DankMaterialShell (DMS) Setup"

    CHOICE=$(show_menu "DMS Action" \
        "Install DMS" \
        "Uninstall DMS" \
        "Enable DMS" \
        "Disable DMS" \
        "Cancel")

    case "$CHOICE" in
        "Install DMS")
            ujust _dms-install-system
            if is_dms_installed && gum confirm "Enable DMS for users now?"; then
                SELECTED=$(select_users "Select users to enable DMS for:")
                for user in $SELECTED; do
                    ujust _dms-enable-user "$user"
                done
            fi
            ;;
        "Uninstall DMS")
            ujust _dms-uninstall-system
            ;;
        "Enable DMS")
            SELECTED=$(select_users "Select users to enable DMS for:")
            for user in $SELECTED; do
                ujust _dms-enable-user "$user"
            done
            ;;
        "Disable DMS")
            SELECTED=$(select_users "Select users to disable DMS for:")
            for user in $SELECTED; do
                ujust _dms-disable-user "$user"
            done
            ;;
        *)
            log_info "Cancelled"
            ;;
    esac

[private]
_dms-install-system:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"

    info_box "Installing DankMaterialShell (DMS)"

    if is_dms_installed; then
        success_box "DMS is already installed"
        exit 0
    fi

    if ! is_dms_copr_enabled; then
        log_info "Enabling DMS COPR repository..."
        dnf copr enable -y avengemedia/dms 2>/dev/null
    fi

    log_info "Installing DMS package..."
    dnf install -y dms 2>/dev/null

    success_box "DMS installed successfully"

[private]
_dms-uninstall-system:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"

    info_box "Uninstalling DankMaterialShell (DMS)"

    if ! is_dms_installed; then
        warn_box "DMS is not installed"
        exit 0
    fi

    log_info "Disabling DMS services and configuration for all users..."

    for user in $(get_all_users); do
        user_home=$(get_user_home "$user")
        if [[ -d "$user_home/.config/yolk" ]]; then
            config_file="$user_home/.config/yolk/eggs/niri/config.kdl"
            if [[ -f "$config_file" ]]; then
                configure_dms_for_user "$user" "false"
            fi
        fi
        run_as_user "$user" systemctl --user disable dms 2>/dev/null || true
        run_as_user "$user" systemctl --user disable dsearch 2>/dev/null || true
    done

    log_info "Removing DMS package..."
    dnf remove -y dms 2>/dev/null || true

    if gum confirm "Remove DMS COPR repository?"; then
        dnf copr remove avengemedia/dms 2>/dev/null || true
    fi

    success_box "DMS uninstalled"

[private]
_dms-enable-user USER:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"

    USER="{{ USER }}"

    if ! is_dms_installed; then
        error_box "DMS is not installed. Run 'ujust dms-setup' first"
        exit 1
    fi

    info_box "Enabling DMS for user: $USER"

    run_as_user "$USER" systemctl --user enable dms 2>/dev/null || true
    run_as_user "$USER" systemctl --user enable dsearch 2>/dev/null || true

    USER_HOME=$(get_user_home "$USER")
    CONFIG_FILE="$USER_HOME/.config/yolk/eggs/niri/config.kdl"

    if [[ -f "$CONFIG_FILE" ]]; then
        configure_dms_for_user "$USER" "true"
        log_info "Updated niri configuration"
    fi

    success_box "DMS enabled for user: $USER"

[private]
_dms-disable-user USER:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"

    USER="{{ USER }}"

    info_box "Disabling DMS for user: $USER"

    run_as_user "$USER" systemctl --user disable dms 2>/dev/null || true
    run_as_user "$USER" systemctl --user disable dsearch 2>/dev/null || true

    USER_HOME=$(get_user_home "$USER")
    CONFIG_FILE="$USER_HOME/.config/yolk/eggs/niri/config.kdl"

    if [[ -f "$CONFIG_FILE" ]]; then
        configure_dms_for_user "$USER" "false"
        log_info "Updated niri configuration"
    fi

    success_box "DMS disabled for user: $USER"

[group('DMS')]
dms-status:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    elevate

    header_box "DankMaterialShell Status"

    info_box "Installation"
    if is_dms_installed; then
        echo "  ✔ DMS installed"
        echo "  ✔ Version: $(dms version 2>/dev/null || echo 'unknown')"
    else
        echo "  ✘ DMS not installed"
    fi

    echo ""
    info_box "Repository"
    if is_dms_copr_enabled; then
        echo "  ✔ COPR enabled"
    else
        echo "  ✘ COPR not enabled"
    fi

    echo ""
    info_box "User Services"
    for user in $(get_all_users); do
        user_home=$(get_user_home "$user")
        if [[ -d "$user_home/.config/yolk" ]]; then
            dms_status="✘"
            dsearch_status="✘"
            run_as_user "$user" systemctl --user is-enabled dms &>/dev/null && dms_status="✔"
            run_as_user "$user" systemctl --user is-enabled dsearch &>/dev/null && dsearch_status="✔"
            echo "  $user: dms=$dms_status dsearch=$dsearch_status"
        fi
    done
