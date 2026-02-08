[group('Setup')]
setup:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    if ! is_root; then
        if request_root "System setup requires root privileges"; then
            exec sudo ujust setup
        fi
        exit 0
    fi

    show_header "System Setup"

    INSTALL_FONTS=false
    INSTALL_ANSIBLE=false
    INSTALL_DOTFILES=false
    INSTALL_DCONF=false
    USE_DMS=false

    echo "=== Component Selection ==="
    echo ""

    gum confirm "Install Maple Mono fonts?" && INSTALL_FONTS=true
    gum confirm "Run Ansible bootstrap?" && INSTALL_ANSIBLE=true

    if gum confirm "Deploy dotfiles?"; then
        INSTALL_DOTFILES=true
        gum confirm "Enable DankMaterialShell (DMS)?" && USE_DMS=true
    fi

    gum confirm "Apply system-wide dconf settings?" && INSTALL_DCONF=true

    echo ""
    echo "=== Setup Summary ==="
    [[ "$INSTALL_FONTS" == "true" ]] && echo "  [✔] Maple Mono fonts"
    [[ "$INSTALL_ANSIBLE" == "true" ]] && echo "  [✔] Ansible bootstrap"
    [[ "$INSTALL_DOTFILES" == "true" ]] && echo "  [✔] Dotfiles"
    [[ "$USE_DMS" == "true" ]] && echo "  [✔] DankMaterialShell enabled"
    [[ "$INSTALL_DCONF" == "true" ]] && echo "  [✔] System dconf settings"
    echo ""

    if ! gum confirm "Proceed with setup?"; then
        log_info "Setup cancelled"
        exit 0
    fi

    FAILED=""

    if [[ "$INSTALL_FONTS" == "true" ]]; then
        echo ""
        echo "--- Step 1: Installing Fonts ---"
        ujust fonts-setup || { log_warn "Font installation failed"; FAILED="${FAILED}fonts "; }
    fi

    if [[ "$INSTALL_ANSIBLE" == "true" ]]; then
        echo ""
        echo "--- Step 2: Ansible Bootstrap ---"
        ujust ansible-bootstrap || { log_warn "Ansible bootstrap failed"; FAILED="${FAILED}ansible "; }
    fi

    if [[ "$INSTALL_DOTFILES" == "true" ]]; then
        echo ""
        echo "--- Step 3: Deploying Dotfiles ---"
        ujust dotfiles-setup || { log_warn "Dotfiles deployment failed"; FAILED="${FAILED}dotfiles "; }
    fi

    if [[ "$INSTALL_DCONF" == "true" ]]; then
        echo ""
        echo "--- Step 4: Applying dconf Settings ---"
        ujust dconf-setup || { log_warn "dconf application failed"; FAILED="${FAILED}dconf "; }
    fi

    echo ""
    if [[ -z "$FAILED" ]]; then
        show_success "Full system setup complete!"
    else
        show_error "Setup completed with failures: $FAILED"
    fi

    echo ""
    echo "Next steps:"
    echo "  - Log out and log back in for all changes to take effect"
    [[ "$USE_DMS" == "true" ]] && echo "  - DMS services have been enabled and will start on next login"

[group('Setup')]
setup-status:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    show_header "Setup Status"

    echo "=== System Type ==="
    if [[ -f /run/ostree-booted ]]; then
        printf "  [✔] Bootc/OSTree system\n"
        if command -v bootc &>/dev/null; then
            bootc status 2>/dev/null | head -10 | sed 's/^/    /'
        fi
    else
        printf "  [✔] Traditional system\n"
    fi

    echo ""
    echo "=== Auto Updates ==="
    if systemctl is-enabled -q uupd.timer 2>/dev/null; then
        printf "  [✔] uupd.timer enabled\n"
    elif systemctl is-enabled -q dnf-automatic.timer 2>/dev/null; then
        printf "  [✔] %-20s enabled\n" "dnf-automatic.timer"
    else
        printf "  [✘] %-20s disabled\n" "dnf-automatic.timer"
    fi

    echo ""
    echo "=== Fonts ==="
    if fc-list : family 2>/dev/null | grep -qi maple; then
        printf "  [✔] %-20s installed\n" "Maple Mono"
    else
        printf "  [✘] %-20s not found\n" "Maple Mono"
    fi

    echo ""
    echo "=== DMS Status ==="
    if is_dms_installed; then
        printf "  [✔] %-20s installed\n" "DMS"
        if is_service_enabled dms user 2>/dev/null; then
            printf "  [✔] %-20s enabled\n" "dms.service"
        else
            printf "  [✘] %-20s disabled\n" "dms.service"
        fi
    else
        printf "  [✘] %-20s not installed\n" "DMS"
    fi

    echo ""
    echo "=== Dotfiles ==="
    if [[ -d "${YOLK_DIR}/.git" ]]; then
        printf "  [✔] %-20s %s\n" "Repository" "${YOLK_DIR}"
        (
            cd "${YOLK_DIR}"
            printf "  [✔] %-20s %s@%s\n" "Version" "$(git branch --show-current 2>/dev/null || echo unknown)" "$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
        )
    else
        printf "  [✘] %-20s not initialized\n" "Repository"
    fi

    if command -v yolk &>/dev/null; then
        echo ""
        echo "=== Yolk Eggs ==="
        yolk list 2>/dev/null | head -20 || true
    fi
