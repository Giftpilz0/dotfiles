[group('Core')]
setup:
    #!/usr/bin/env bash
    source "{{ justfile_directory() }}/lib/common.sh"
    elevate
    mapfile -t default_dotfile_users < <(default_dotfile_users)
    mapfile -t default_ansible_users < <(default_ansible_users)
    header_box "Setup"
    mapfile -t dotfile_users < <(resolve_target_users "Select users for setup" any "${default_dotfile_users[@]}")
    mapfile -t ansible_users < <(resolve_target_users "Select non-root users for Ansible" non-root "${default_ansible_users[@]}")
    header_box "Ansible"
    run_ansible_for_users "${ansible_users[@]}"
    header_box "Dotfiles"
    apply_dotfiles_for_users "${dotfile_users[@]}"
    success_box "Setup complete"

[group('Core')]
status:
    #!/usr/bin/env bash
    source "{{ justfile_directory() }}/lib/common.sh"
    elevate
    mapfile -t default_users < <(default_status_users)
    mapfile -t target_users < <(resolve_target_users "Select users for status" any "${default_users[@]}")

    header_box "Status"

    info_box "System"
    if is_bootc_system; then
        echo "  Type: bootc/ostree"
        if command -v bootc >/dev/null 2>&1; then
            bootc status 2>/dev/null | head -10 | sed 's/^/    /'
        fi
    else
        echo "  Type: mutable Fedora"
    fi
    echo "  ujust repo: ${UJUST_REPO}"

    echo ""
    info_box "Dotfiles"
    print_dotfiles_status_for_users "${target_users[@]}"

    echo ""
    info_box "Provisioning"
    if [[ -d "${UJUST_REPO}/ansible" ]]; then
        echo "  Ansible bundle: ${UJUST_REPO}/ansible"
    else
        echo "  Ansible bundle: missing"
    fi
