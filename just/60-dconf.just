[group('Dconf')]
dconf-setup:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    elevate

    header_box "Applying dconf Settings"

    SELECTED=$(select_users "Select users to apply dconf settings for:")
    [[ -z "$SELECTED" ]] && exit 0

    ujust _dconf-apply "$SELECTED"

[private]
_dconf-apply USERS:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"

    USERS="{{ USERS }}"

    DCONF_SRC="${UJUST_REPO}/misc/dconf"

    if [[ ! -d "$DCONF_SRC" ]]; then
        error_box "dconf source directory not found: $DCONF_SRC"
        exit 1
    fi

    info_box "Installing dconf files..."

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

    for user in $USERS; do
        user_home=$(get_user_home "$user")
        if [[ -d "$user_home" ]]; then
            log_info "Resetting dconf for user: $user"
            if [[ "$user" == "root" ]]; then
                dbus-run-session -- dconf reset -f / 2>/dev/null || warn_box "Could not reset dconf for $user"
            else
                run_as_user "$user" bash -c "dbus-run-session -- dconf reset -f /" 2>/dev/null || warn_box "Could not reset dconf for $user"
            fi
        fi
    done

    success_box "dconf settings applied"


[group('Dconf')]
dconf-status:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    elevate

    header_box "dconf Status"

    info_box "Database Files"
    for file in /etc/dconf/profile/user /etc/dconf/db/local.d/dconf.ini; do
        if [[ -f "$file" ]]; then
            echo "  ✔ $file"
        else
            echo "  ✘ $file"
        fi
    done
