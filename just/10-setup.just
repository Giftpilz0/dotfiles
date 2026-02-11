[group('Setup')]
setup:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    elevate

    header_box "System Setup"

    SELECTED=$(select_users "Select users to configure:")
    [[ -z "$SELECTED" ]] && exit 0

    declare -A COMPONENTS
    COMPONENTS[fonts]=false
    COMPONENTS[ansible]=false
    COMPONENTS[dotfiles]=false
    COMPONENTS[dconf]=false
    COMPONENTS[dms]=false

    info_box "Component Selection"

    if gum confirm "Install Maple Mono fonts?"; then
        COMPONENTS[fonts]=true
    fi

    if gum confirm "Run Ansible bootstrap?"; then
        COMPONENTS[ansible]=true
    fi

    if gum confirm "Deploy dotfiles?"; then
        COMPONENTS[dotfiles]=true
        if gum confirm "Enable DankMaterialShell (DMS) by default?"; then
            COMPONENTS[dms]=true
        fi
    fi

    if gum confirm "Apply system-wide dconf settings?"; then
        COMPONENTS[dconf]=true
    fi

    echo ""
    info_box "Setup Summary"

    summary=""
    [[ "${COMPONENTS[fonts]}" == "true" ]] && summary+="  ✔ Maple Mono fonts\n"
    [[ "${COMPONENTS[ansible]}" == "true" ]] && summary+="  ✔ Ansible bootstrap\n"
    [[ "${COMPONENTS[dotfiles]}" == "true" ]] && summary+="  ✔ Dotfiles\n"
    [[ "${COMPONENTS[dms]}" == "true" ]] && summary+="  ✔ DankMaterialShell enabled\n"
    [[ "${COMPONENTS[dconf]}" == "true" ]] && summary+="  ✔ System dconf settings\n"

    if [[ -z "$summary" ]]; then
        warn_box "No components selected"
        exit 0
    fi

    echo -e "$summary"
    echo ""
    info_box "Selected users: $SELECTED"

    if ! gum confirm "Proceed with setup?"; then
        log_info "Setup cancelled"
        exit 0
    fi

    FAILED=""

    if [[ "${COMPONENTS[fonts]}" == "true" ]]; then
        echo ""
        info_box "Step 1: Installing Fonts"
        ujust _fonts-install || { log_warn "Font installation failed"; FAILED+="fonts "; }
    fi

    if [[ "${COMPONENTS[ansible]}" == "true" ]]; then
        echo ""
        info_box "Step 2: Ansible Bootstrap"
        ujust ansible-bootstrap || { log_warn "Ansible bootstrap failed"; FAILED+="ansible "; }
    fi

    if [[ "${COMPONENTS[dotfiles]}" == "true" ]]; then
        echo ""
        info_box "Step 3: Deploying Dotfiles"
        for user in $SELECTED; do
            USER_USE_DMS="${COMPONENTS[dms]}"
            if [[ "${COMPONENTS[dms]}" == "true" ]]; then
                if ! gum confirm "Enable DMS for $user?"; then
                    USER_USE_DMS="false"
                fi
            fi
            ujust _dotfiles-deploy-user "$user" "$USER_USE_DMS" || { log_warn "Dotfiles deployment failed for $user"; FAILED+="dotfiles-$user "; }
        done
    fi

    if [[ "${COMPONENTS[dconf]}" == "true" ]]; then
        echo ""
        info_box "Step 4: Applying dconf Settings"
        ujust _dconf-apply "$SELECTED" || { log_warn "dconf application failed"; FAILED+="dconf "; }
    fi

    echo ""
    if [[ -z "$FAILED" ]]; then
        success_box "Full system setup complete!"
    else
        error_box "Setup completed with failures: $FAILED"
    fi

    echo ""
    info_box "Next steps:"
    echo "  • Log out and log back in for all changes to take effect"
    if [[ "${COMPONENTS[dms]}" == "true" ]]; then
        echo "  • DMS services have been enabled for selected users"
    fi

[group('Setup')]
setup-status:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    elevate

    header_box "Setup Status"

    info_box "System Type"
    if [[ -f /run/ostree-booted ]]; then
        echo "  ✔ Bootc/OSTree system"
        if command -v bootc &>/dev/null; then
            bootc status 2>/dev/null | head -10 | sed 's/^/    /'
        fi
    else
        echo "  ✔ Traditional system"
    fi

    echo ""
    info_box "Auto Updates"
    if systemctl is-enabled -q uupd.timer 2>/dev/null; then
        echo "  ✔ uupd.timer enabled"
    elif systemctl is-enabled -q dnf-automatic.timer 2>/dev/null; then
        echo "  ✔ dnf-automatic.timer enabled"
    else
        echo "  ✘ dnf-automatic.timer disabled"
    fi

    echo ""
    info_box "Fonts"
    if are_maple_fonts_installed; then
        echo "  ✔ Maple Mono installed"
    else
        echo "  ✘ Maple Mono not found"
    fi

    echo ""
    info_box "DMS Status"
    if is_dms_installed; then
        echo "  ✔ DMS installed"
    else
        echo "  ✘ DMS not installed"
    fi

    echo ""
    info_box "Users"
    for user in $(get_all_users); do
        USER_HOME=$(get_user_home "$user")
        YOLK_USER_DIR="$USER_HOME/.config/yolk"
        if [[ -d "${YOLK_USER_DIR}/.git" ]]; then
            echo "  ✔ $user: dotfiles installed"
        else
            echo "  ✘ $user: no dotfiles"
        fi
    done
