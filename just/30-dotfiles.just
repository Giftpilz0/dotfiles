DOTFILES_PATHS := "${HOME}/.bashrc,${HOME}/.bashrc.d,${HOME}/.config/DankMaterialShell,${HOME}/.config/dgop,${HOME}/.config/gtk-3.0,${HOME}/.config/gtk-4.0,${HOME}/.config/helix,${HOME}/.config/kitty,${HOME}/.config/matugen,${HOME}/.config/niri,${HOME}/.config/quickshell,${HOME}/.config/vim,${HOME}/.config/wofi,${HOME}/.config/xdg-desktop-portal,${HOME}/.var/app/dev.zed.Zed/config/zed,${HOME}/.config/libreoffice/4/user/registrymodifications.xcu,${HOME}/.inputrc,${HOME}/.config/systemd"

[group('Dotfiles')]
dotfiles-setup:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    show_header "Dotfiles Setup"

    if ! is_root; then
        ujust _dotfiles-deploy-user "$(whoami)"
        exit 0
    fi

    USERS=$(get_regular_users)
    ALL_USERS=$(echo -e "${USERS}\nroot")

    if [[ -z "$ALL_USERS" ]]; then
        log_warn "No users found"
        exit 1
    fi

    echo "Select users to deploy dotfiles for (space to select, enter to confirm):"
    SELECTED=$(echo "$ALL_USERS" | gum choose --no-limit)
    [[ -z "$SELECTED" ]] && exit 0

    USE_DMS="false"
    if gum confirm "Enable DankMaterialShell (DMS) by default?"; then
        USE_DMS="true"
    fi

    for user in $SELECTED; do
        USER_USE_DMS="$USE_DMS"
        if [[ "$USE_DMS" == "true" ]]; then
            gum confirm "Enable DMS for $user?" || USER_USE_DMS="false"
        fi
        ujust _dotfiles-deploy-user "$user" "$USER_USE_DMS"
    done

[private]
_dotfiles-deploy-user USER USE_DMS="false":
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    USER="{{ USER }}"
    USE_DMS="{{ USE_DMS }}"
    USER_HOME=$(get_user_home "$USER")

    if [[ -z "$USER_HOME" ]] || [[ ! -d "$USER_HOME" ]]; then
        log_error "Home directory not found for user: $USER"
        exit 1
    fi

    show_header "Deploying Dotfiles for: $USER"

    YOLK_USER_DIR="$USER_HOME/.config/yolk"

    if [[ -d "${YOLK_USER_DIR}/.git" ]]; then
        log_info "Updating repository..."
        if [[ "$USER" == "$(whoami)" ]]; then
            (cd "$YOLK_USER_DIR" && git pull 2>/dev/null)
        else
            run_as_user "$USER" bash -c "cd '$YOLK_USER_DIR' && git pull" 2>/dev/null
        fi
    else
        log_info "Cloning dotfiles repository..."
        if [[ "$USER" == "$(whoami)" ]]; then
            git clone --depth 1 "https://github.com/Giftpilz0/dotfiles.git" "$YOLK_USER_DIR" 2>/dev/null
        else
            run_as_user "$USER" git clone --depth 1 "https://github.com/Giftpilz0/dotfiles.git" "$YOLK_USER_DIR" 2>/dev/null
        fi
    fi

    log_info "Cleaning old dotfiles..."
    export HOME="$USER_HOME"
    IFS=',' read -ra DIRS <<< "{{ DOTFILES_PATHS }}"
    for d in "${DIRS[@]}"; do
        d="${d//\$HOME/$HOME}"
        d="${d//\~/$HOME}"
        [[ -L "$d" ]] && unlink "$d" 2>/dev/null || true
        [[ -d "$d" ]] && rm -rf "$d" 2>/dev/null || true
        [[ -f "$d" ]] && rm -f "$d" 2>/dev/null || true
    done

    if [[ -f "$YOLK_USER_DIR/eggs/niri/config.kdl" ]]; then
        configure_dms "$USE_DMS"
    fi

    if check_command yolk; then
        log_info "Running yolk sync..."
        if [[ "$USER" == "$(whoami)" ]]; then
            (cd "$YOLK_USER_DIR" && yolk sync 2>/dev/null) || log_warn "Yolk sync completed with warnings"
        else
            run_as_user "$USER" bash -c "cd '$YOLK_USER_DIR' && yolk sync" 2>/dev/null || log_warn "Yolk sync completed with warnings"
        fi
    fi

    if [[ "$USER" == "$(whoami)" ]]; then
        enable_service "ssh-agent" "user"
        if [[ "$USE_DMS" == "true" ]]; then
            enable_service "dms" "user"
            enable_service "dsearch" "user"
        fi
    else
        # When running as root for another user, enable services for that user
        run_as_user "$USER" systemctl --user enable ssh-agent 2>/dev/null || true
        if [[ "$USE_DMS" == "true" ]]; then
            run_as_user "$USER" systemctl --user enable dms 2>/dev/null || true
            run_as_user "$USER" systemctl --user enable dsearch 2>/dev/null || true
        fi
    fi

    log_info "Deployment complete for user: $USER"

[group('Dotfiles')]
dotfiles-status:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    show_header "Dotfiles Status"

    if ! is_root; then
        YOLK_DIR="${HOME}/.config/yolk"
        if [[ -d "${YOLK_DIR}/.git" ]]; then
            echo "=== Repository ==="
            echo "  Location: $YOLK_DIR"
            (cd "$YOLK_DIR" && echo "  Branch: $(git branch --show-current 2>/dev/null || echo unknown)" && \
                echo "  Commit: $(git rev-parse --short HEAD 2>/dev/null || echo unknown)")
        else
            log_error "Dotfiles repository not found"
        fi

        if check_command yolk; then
            echo ""
            echo "=== Yolk Eggs ==="
            yolk list 2>/dev/null || true
        fi
    else
        for user in $(get_regular_users) root; do
            USER_HOME=$(get_user_home "$user")
            YOLK_USER_DIR="$USER_HOME/.config/yolk"
            if [[ -d "${YOLK_USER_DIR}/.git" ]]; then
                echo "=== User: $user ==="
                (cd "$YOLK_USER_DIR" && echo "  Branch: $(git branch --show-current 2>/dev/null || echo unknown)" && \
                    echo "  Commit: $(git rev-parse --short HEAD 2>/dev/null || echo unknown)")
                echo ""
            fi
        done
    fi

[group('Dotfiles')]
dotfiles-update:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    show_header "Syncing Dotfiles from Git"

    if ! is_root; then
        YOLK_DIR="${HOME}/.config/yolk"
        [[ -d "${YOLK_DIR}/.git" ]] || { log_error "Dotfiles not installed as git repo"; exit 1; }
        (cd "$YOLK_DIR" && git pull 2>/dev/null)
        check_command yolk && (cd "$YOLK_DIR" && yolk sync 2>/dev/null)
        show_success "Dotfiles synced for $(whoami)"
    else
        for user in $(get_regular_users) root; do
            USER_HOME=$(get_user_home "$user")
            YOLK_USER_DIR="$USER_HOME/.config/yolk"
            if [[ -d "${YOLK_USER_DIR}/.git" ]]; then
                log_info "Syncing for user: $user"
                if [[ "$user" == "root" ]]; then
                    (cd "$YOLK_USER_DIR" && git pull 2>/dev/null) || log_warn "Failed to sync for $user"
                else
                    run_as_user "$user" bash -c "cd '$YOLK_USER_DIR' && git pull" 2>/dev/null || log_warn "Failed to sync for $user"
                fi
            fi
        done
        show_success "Dotfiles synced for all users"
    fi
