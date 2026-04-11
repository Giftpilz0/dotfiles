[group('Core')]
dotfiles-apply:
    #!/usr/bin/env bash
    source "{{ justfile_directory() }}/lib/common.sh"
    elevate

    header_box "Dotfiles"
    mapfile -t default_users < <(default_dotfile_users)
    mapfile -t target_users < <(resolve_target_users "Select users for dotfiles apply" any "${default_users[@]}")
    apply_dotfiles_for_users "${target_users[@]}"
    success_box "Dotfiles applied"

[private]
_dotfiles-apply-user USER:
    #!/usr/bin/env bash
    source "{{ justfile_directory() }}/lib/common.sh"

    target_user="{{ USER }}"
    info_box "Applying dotfiles for ${target_user}"
    apply_dotfiles_for_user "$target_user"
    success_box "Dotfiles applied for ${target_user}"

[private]
_dotfiles-apply-current-user:
    #!/usr/bin/env bash
    source "{{ justfile_directory() }}/lib/common.sh"

    target_user="$(whoami)"
    info_box "Applying dotfiles for ${target_user}"
    apply_dotfiles_for_user "$target_user"
    success_box "Dotfiles applied for ${target_user}"

[group('Core')]
dotfiles-update:
    #!/usr/bin/env bash
    source "{{ justfile_directory() }}/lib/common.sh"
    elevate

    header_box "Dotfiles"
    mapfile -t default_users < <(default_dotfile_users)
    mapfile -t target_users < <(resolve_target_users "Select users for dotfiles update" any "${default_users[@]}")
    update_dotfiles_for_users "${target_users[@]}"
    success_box "Dotfiles updated"
