[group('DMS')]
dms-setup:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    show_header "DankMaterialShell (DMS) Setup"

    CHOICE=$(gum choose --header="DMS Action" \
        "Install DMS" \
        "Uninstall DMS" \
        "Enable DMS" \
        "Disable DMS" \
        "Cancel")

    case "$CHOICE" in
        "Install DMS")
            ujust _dms-install-system
            if is_dms_installed && gum confirm "Enable DMS now?"; then
                USERS=$(get_regular_users)
                ALL_USERS=$(echo -e "${USERS}\nroot")
                if [[ -n "$ALL_USERS" ]]; then
                    echo "Enable DMS for which users?"
                    SELECTED=$(echo "$ALL_USERS" | gum choose --no-limit)
                    for user in $SELECTED; do
                        if [[ "$user" == "$(whoami)" ]]; then
                            ujust _dms-enable-user || true
                        else
                            run_as_user "$user" ujust _dms-enable-user || true
                        fi
                    done
                fi
            fi
            ;;
        "Uninstall DMS")
            ujust _dms-uninstall-system
            ;;
        "Enable DMS")
            USERS=$(get_regular_users)
            ALL_USERS=$(echo -e "${USERS}\nroot")
            if [[ -n "$ALL_USERS" ]]; then
                echo "Enable DMS for which users?"
                SELECTED=$(echo "$ALL_USERS" | gum choose --no-limit)
                for user in $SELECTED; do
                    if [[ "$user" == "$(whoami)" ]]; then
                        ujust _dms-enable-user || true
                    else
                        run_as_user "$user" ujust _dms-enable-user || true
                    fi
                done
            fi
            ;;
        "Disable DMS")
            USERS=$(get_regular_users)
            ALL_USERS=$(echo -e "${USERS}\nroot")
            if [[ -n "$ALL_USERS" ]]; then
                echo "Disable DMS for which users?"
                SELECTED=$(echo "$ALL_USERS" | gum choose --no-limit)
                for user in $SELECTED; do
                    if [[ "$user" == "$(whoami)" ]]; then
                        ujust _dms-disable-user || true
                    else
                        run_as_user "$user" ujust _dms-disable-user || true
                    fi
                done
            fi
            ;;
        *)
            log_info "Cancelled"
            ;;
    esac

[private]
_dms-install-system:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    if ! is_root; then
        if request_root "DMS installation requires root privileges"; then
            exec sudo ujust _dms-install-system
        fi
        exit 0
    fi

    show_header "Installing DankMaterialShell (DMS)"

    if is_dms_installed; then
        log_info "DMS is already installed"
        exit 0
    fi

    if ! is_dms_copr_enabled; then
        log_info "Enabling DMS COPR repository..."
        dnf copr enable -y avengemedia/dms 2>/dev/null
    fi

    log_info "Installing DMS package..."
    dnf install -y dms 2>/dev/null

    show_success "DMS installed successfully"

[private]
_dms-uninstall-system:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    if ! is_root; then
        if request_root "Removing DMS requires root privileges"; then
            exec sudo ujust _dms-uninstall-system
        fi
        exit 0
    fi

    show_header "Uninstalling DankMaterialShell (DMS)"

    if ! is_dms_installed; then
        log_warn "DMS is not installed"
        exit 0
    fi

    log_info "Disabling DMS services and configuration for all users..."

    for user in $(get_regular_users) root; do
        user_home=$(get_user_home "$user")
        if [[ -d "$user_home/.config/yolk" ]]; then
            config_file="$user_home/.config/yolk/eggs/niri/config.kdl"
            if [[ -f "$config_file" ]]; then
                configure_dms_for_user "$user" "false"
            fi
        fi
        if [[ "$user" == "root" ]]; then
            systemctl --user disable dms dsearch 2>/dev/null || true
        else
            run_as_user "$user" systemctl --user disable dms dsearch 2>/dev/null || true
        fi
    done

    log_info "Removing DMS package..."
    dnf remove -y dms 2>/dev/null || true

    if gum confirm "Remove DMS COPR repository?"; then
        dnf copr remove avengemedia/dms 2>/dev/null || true
    fi

    show_success "DMS uninstalled"

[private]
_dms-enable-user:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    if ! is_dms_installed; then
        log_error "DMS is not installed. Run 'ujust dms-setup' and select Install first"
        exit 1
    fi

    manage_dms_services "true"

    CONFIG_FILE="${HOME}/.config/yolk/eggs/niri/config.kdl"

    if [[ -f "$CONFIG_FILE" ]]; then
        configure_dms "true"
        log_info "Updated niri configuration"
    fi

    log_info "DMS enabled for user: $(whoami)"

[private]
_dms-disable-user:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    manage_dms_services "false"

    CONFIG_FILE="${HOME}/.config/yolk/eggs/niri/config.kdl"

    if [[ -f "$CONFIG_FILE" ]]; then
        configure_dms "false"
        log_info "Updated niri configuration"
    fi

    log_info "DMS disabled for user: $(whoami)"

[group('DMS')]
dms-status:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    show_header "DankMaterialShell Status"

    echo "=== Installation ==="
    if is_dms_installed; then
        printf "  [✔] %-20s installed\n" "DMS"
        printf "  [✔] %-20s %s\n" "Version" "$(dms version 2>/dev/null || echo 'unknown')"
    else
        printf "  [✘] %-20s not installed\n" "DMS"
    fi

    echo ""
    echo "=== Repository ==="
    if is_dms_copr_enabled; then
        printf "  [✔] %-20s enabled\n" "COPR"
    else
        printf "  [✘] %-20s not enabled\n" "COPR"
    fi

    echo ""
    echo "=== User Services ==="
    for svc in dms dsearch; do
        if service_exists "$svc" "user"; then
            status="disabled"
            if is_service_enabled "$svc" "user" 2>/dev/null; then
                status="enabled"
            fi
            printf "  [%s] %-20s %s\n" "$([[ "$status" == "enabled" ]] && echo '✔' || echo '✘')" "${svc}.service" "$status"
        else
            printf "  [✘] %-20s not found\n" "${svc}.service"
        fi
    done

    echo ""
    echo "=== Niri Configuration ==="
    CONFIG_FILE="${HOME}/.config/yolk/eggs/niri/config.kdl"
    if [[ -f "$CONFIG_FILE" ]]; then
        if grep -q "misc/dms.kdl" "$CONFIG_FILE" && ! grep "misc/dms.kdl" "$CONFIG_FILE" | grep -q "^//"; then
            printf "  [✔] %-20s enabled\n" "DMS config"
        else
            printf "  [✘] %-20s disabled\n" "DMS config"
        fi
    else
        printf "  [⚠] %-20s not found\n" "Niri config"
    fi
