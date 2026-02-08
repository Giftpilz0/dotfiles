[group('Dconf')]
dconf-setup:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    if ! is_root; then
        if request_root "Applying dconf settings requires root privileges"; then
            exec sudo ujust dconf-setup
        fi
        exit 0
    fi

    show_header "Applying dconf Settings"

    YOLK_DIR="/usr/share/ujust/yolk"
    DCONF_SRC="${YOLK_DIR}/misc/dconf"

    if [[ ! -d "$DCONF_SRC" ]]; then
        YOLK_DIR="${HOME}/.config/yolk"
        DCONF_SRC="${YOLK_DIR}/misc/dconf"
    fi

    if [[ ! -d "$DCONF_SRC" ]]; then
        log_warn "dconf source directory not found: $DCONF_SRC"
        exit 1
    fi

    if [[ -f "${DCONF_SRC}/usr/share/backgrounds/background" ]]; then
        log_info "Installing background image..."
        mkdir -p /usr/share/backgrounds
        cp "${DCONF_SRC}/usr/share/backgrounds/background" /usr/share/backgrounds/
    fi

    if [[ -f "${DCONF_SRC}/etc/dconf/profile/user" ]]; then
        log_info "Installing dconf profile..."
        mkdir -p /etc/dconf/profile
        cp "${DCONF_SRC}/etc/dconf/profile/user" /etc/dconf/profile/
    fi

    if [[ -f "${DCONF_SRC}/etc/dconf/db/local.d/dconf.ini" ]]; then
        log_info "Installing dconf database..."
        mkdir -p /etc/dconf/db/local.d
        cp "${DCONF_SRC}/etc/dconf/db/local.d/dconf.ini" /etc/dconf/db/local.d/
    fi

    log_info "Updating dconf database..."
    dconf update

    USERS=$(get_regular_users)
    for user in $USERS; do
        user_home=$(get_user_home "$user")
        if [[ -d "$user_home" ]]; then
            log_info "Resetting dconf for user: $user"
            su - "$user" -c "dbus-run-session -- dconf reset -f /" 2>/dev/null || log_warn "Could not reset dconf for $user"
        fi
    done

    show_success "dconf settings applied for all users"

[group('Dconf')]
dconf-update: dconf-setup
    @echo "[✔] dconf updated"

[group('Dconf')]
dconf-status:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    show_header "dconf Status"

    echo "=== Database Files ==="
    for file in /etc/dconf/profile/user /etc/dconf/db/local.d/dconf.ini; do
        if [[ -f "$file" ]]; then
            printf "  [✔] %s\n" "$file"
        else
            printf "  [✘] %s\n" "$file"
        fi
    done

    echo ""
    echo "=== Sources ==="
    YOLK_DIR="${HOME}/.config/yolk"
    DCONF_SRC="${YOLK_DIR}/misc/dconf"

    if [[ -d "$DCONF_SRC" ]]; then
        printf "  [✔] Source directory: %s\n" "$DCONF_SRC"
    else
        printf "  [✘] Source directory not found\n"
    fi
