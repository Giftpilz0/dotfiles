[group('Ansible')]
ansible-bootstrap:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    show_header "Ansible Bootstrap"

    YOLK_DIR="${HOME}/.config/yolk"

    if [[ ! -d "${YOLK_DIR}/ansible" ]]; then
        log_error "Ansible directory not found at ${YOLK_DIR}/ansible"
        exit 1
    fi

    cd "${YOLK_DIR}/ansible"

    log_info "Installing Ansible collections..."
    ansible-galaxy collection install --force "git+https://github.com/Giftpilz0/ansible-collection-general.git" >/dev/null 2>&1 || log_warn "Failed to install general collection"
    ansible-galaxy collection install --force "git+https://github.com/Giftpilz0/ansible-collection-server.git" >/dev/null 2>&1 || log_warn "Failed to install server collection"

    INVENTORY="inventory/workstation"
    if [[ -f /run/ostree-booted ]] || [[ -f /run/.containerenv ]]; then
        INVENTORY="inventory/bootc"
        log_info "Detected bootc/container system, using $INVENTORY"
    fi

    log_info "Running Ansible playbook..."
    echo ""

    if ansible-playbook --connection=local -i "$INVENTORY" "play.yml" --extra-vars "ansible_user=${USER}"; then
        show_success "Ansible provisioning complete"
    else
        show_error "Ansible playbook execution failed"
        exit 1
    fi

[group('Ansible')]
ansible-status:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    show_header "Ansible Status"

    echo "=== Installed Collections ==="
    ansible-galaxy collection list 2>/dev/null || echo "  No collections installed"
