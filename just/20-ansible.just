[group('Ansible')]
ansible-bootstrap:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"

    header_box "Ansible Bootstrap"

    if [[ ! -d "${YOLK_DIR}/ansible" ]]; then
        error_box "Ansible directory not found at ${YOLK_DIR}/ansible"
        exit 1
    fi

    cd "${YOLK_DIR}/ansible"

    log_info "Installing Ansible collections..."
    ansible-galaxy collection install --force "git+https://github.com/Giftpilz0/homelab.git#/ansible_collections/giftpilz0/general" >/dev/null 2>&1 || log_warn "Failed to install general collection"
    ansible-galaxy collection install --force "git+https://github.com/Giftpilz0/homelab.git#/ansible_collections/giftpilz0/server" >/dev/null 2>&1 || log_warn "Failed to install server collection"

    INVENTORY="inventory/workstation"
    if [[ -f /run/ostree-booted ]] || [[ -f /run/.containerenv ]]; then
        INVENTORY="inventory/bootc"
        log_info "Detected bootc/container system, using $INVENTORY"
    fi

    log_info "Running Ansible playbook..."
    echo ""

    if ansible-playbook --connection=local -i "$INVENTORY" "play.yml" --extra-vars "ansible_user=${USER}"; then
        success_box "Ansible provisioning complete"
    else
        error_box "Ansible playbook execution failed"
        exit 1
    fi

[group('Ansible')]
ansible-status:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"

    header_box "Ansible Status"

    info_box "Installed Collections"
    ansible-galaxy collection list 2>/dev/null || echo "  No collections installed"
