[group('Core')]
ansible-apply:
    #!/usr/bin/env bash
    source "{{ justfile_directory() }}/lib/common.sh"
    elevate

    header_box "Ansible"
    mapfile -t default_users < <(default_ansible_users)
    mapfile -t target_users < <(resolve_target_users "Select non-root users for Ansible" non-root "${default_users[@]}")
    run_ansible_for_users "${target_users[@]}"
    success_box "Ansible provisioning complete"
