[group('Core')]
update:
    #!/usr/bin/env bash
    source "{{ justfile_directory() }}/lib/common.sh"
    elevate

    header_box "Update"
    update_system
    header_box "Dotfiles"
    mapfile -t default_users < <(default_dotfile_users)
    mapfile -t target_users < <(resolve_target_users "Select users for update" any "${default_users[@]}")
    update_dotfiles_for_users "${target_users[@]}"
    success_box "Update complete"
