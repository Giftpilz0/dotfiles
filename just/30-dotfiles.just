DOTFILES_PATHS := "${HOME}/.bashrc,${HOME}/.bashrc.d,${HOME}/.config/DankMaterialShell,${HOME}/.config/dgop,${HOME}/.config/gtk-3.0,${HOME}/.config/gtk-4.0,${HOME}/.config/helix,${HOME}/.config/kitty,${HOME}/.config/matugen,${HOME}/.config/niri,${HOME}/.config/quickshell,${HOME}/.config/vim,${HOME}/.config/wofi,${HOME}/.config/fuzzel,${HOME}/.config/xdg-desktop-portal,${HOME}/.var/app/dev.zed.Zed/config/zed,${HOME}/.config/libreoffice/4/user/registrymodifications.xcu,${HOME}/.inputrc,${HOME}/.config/systemd"

[group('Dotfiles')]
dotfiles-setup:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    elevate

    header_box "Dotfiles Setup"

    SELECTED=$(select_users "Select users to deploy dotfiles for:")
    [[ -z "$SELECTED" ]] && exit 0

    USE_DMS="false"
    if gum confirm "Enable DankMaterialShell (DMS) by default?"; then
        USE_DMS="true"
    fi

    for user in $SELECTED; do
        echo ""
        USER_USE_DMS="$USE_DMS"
        if [[ "$USE_DMS" == "true" ]]; then
            if ! gum confirm "Enable DMS for $user?"; then
                USER_USE_DMS="false"
            fi
        fi
        ujust _dotfiles-deploy-user "$user" "$USER_USE_DMS"
    done

[private]
_dotfiles-deploy-user USER USE_DMS="false":
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"

    USER="{{ USER }}"
    USE_DMS="{{ USE_DMS }}"
    USER_HOME=$(get_user_home "$USER")

    if [[ -z "$USER_HOME" ]] || [[ ! -d "$USER_HOME" ]]; then
        error_box "Home directory not found for user: $USER"
        exit 1
    fi

    info_box "Deploying Dotfiles for: $USER"

    YOLK_USER_DIR="$USER_HOME/.config/yolk"

    if [[ -d "${YOLK_USER_DIR}/.git" ]]; then
        log_info "Repository exists, updating..."
        run_as_user "$USER" bash -c "cd '$YOLK_USER_DIR' && git pull --rebase --autostash" 2>/dev/null || {
            warn_box "Local changes detected for $USER"
            if gum confirm "Override local changes for $USER?"; then
                run_as_user "$USER" bash -c "cd '$YOLK_USER_DIR' && git reset --hard HEAD && git pull --rebase" 2>/dev/null || true
            fi
        }
    else
        log_info "Cloning dotfiles repository..."
        run_as_user "$USER" git clone "https://github.com/Giftpilz0/dotfiles.git" "$YOLK_USER_DIR" 2>/dev/null
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
        configure_dms_for_user "$USER" "$USE_DMS"
    fi

    if check_command yolk; then
        log_info "Running yolk sync..."
        run_as_user "$USER" bash -c "cd '$YOLK_USER_DIR' && yolk sync --yolk-dir $YOLK_USER_DIR" 2>/dev/null || log_warn "Yolk sync completed with warnings"
    fi

    # Enable user services
    run_as_user "$USER" systemctl --user enable ssh-agent 2>/dev/null || true
    if [[ "$USE_DMS" == "true" ]]; then
        run_as_user "$USER" systemctl --user enable dms 2>/dev/null || true
        run_as_user "$USER" systemctl --user enable dsearch 2>/dev/null || true
    fi

    success_box "Deployment complete for user: $USER"

[group('Dotfiles')]
dotfiles-status:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    elevate

    header_box "Dotfiles Status"

    info_box "System Repository"
    if [[ -d "${UJUST_REPO}/.git" ]]; then
        echo "  Location: $UJUST_REPO"
        (cd "$UJUST_REPO" && echo "  Branch: $(git branch --show-current 2>/dev/null || echo unknown)" && \
            echo "  Commit: $(git rev-parse --short HEAD 2>/dev/null || echo unknown)")
    else
        echo "  ✘ System repository not found"
    fi

    echo ""
    info_box "User Repositories"

    for user in $(get_all_users); do
        USER_HOME=$(get_user_home "$user")
        YOLK_USER_DIR="$USER_HOME/.config/yolk"
        if [[ -d "${YOLK_USER_DIR}/.git" ]]; then
            info_box "User: $user"
            (cd "$YOLK_USER_DIR" && echo "  Branch: $(git branch --show-current 2>/dev/null || echo unknown)" && \
                echo "  Commit: $(git rev-parse --short HEAD 2>/dev/null || echo unknown)")
            echo ""
        fi
    done

[group('Dotfiles')]
dotfiles-update:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    elevate

    header_box "Syncing Dotfiles from Git"

    # Update system repo first
    info_box "Updating system repository..."
    (cd "$UJUST_REPO" && git pull --rebase --autostash 2>/dev/null) || warn_box "Could not update system repository"

    SELECTED=$(select_users "Select users to sync dotfiles for:")
    [[ -z "$SELECTED" ]] && exit 0

    for user in $SELECTED; do
        USER_HOME=$(get_user_home "$user")
        YOLK_USER_DIR="$USER_HOME/.config/yolk"
        if [[ -d "${YOLK_USER_DIR}/.git" ]]; then
            info_box "Syncing for user: $user"

            run_as_user "$user" bash -c "cd '$YOLK_USER_DIR' && git pull --rebase --autostash" 2>/dev/null || {
                warn_box "Local changes detected for $user"
                if gum confirm "Override changes for $user?"; then
                    run_as_user "$user" bash -c "cd '$YOLK_USER_DIR' && git reset --hard HEAD && git pull --rebase" 2>/dev/null || true
                elif gum confirm "Stash changes for $user?"; then
                    run_as_user "$user" bash -c "cd '$YOLK_USER_DIR' && git stash && git pull --rebase && git stash pop" 2>/dev/null || true
                fi
            }

            if check_command yolk; then
                run_as_user "$user" bash -c "cd '$YOLK_USER_DIR' && yolk sync --yolk-dir $YOLK_USER_DIR" 2>/dev/null || log_warn "Yolk sync had warnings for $user"
            fi
        fi
    done

    success_box "Dotfiles synced"
