import "/usr/share/ujust/dotfiles/just/10-setup.just"
import "/usr/share/ujust/dotfiles/just/20-ansible.just"
import "/usr/share/ujust/dotfiles/just/30-dotfiles.just"
import "/usr/share/ujust/dotfiles/just/40-dms.just"
import "/usr/share/ujust/dotfiles/just/50-fonts.just"
import "/usr/share/ujust/dotfiles/just/60-dconf.just"
import "/usr/share/ujust/dotfiles/just/70-system.just"

[group('General')]
default:
    @ujust --list

[group('Maintenance')]
update:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    elevate

    header_box "Updating System"

    if command -v bootc &>/dev/null && [[ -f /run/ostree-booted ]]; then
        log_info "Detected bootc system"
        bootc upgrade
    elif command -v dnf &>/dev/null; then
        log_info "Detected dnf-based system"
        dnf upgrade -y
    else
        error_box "No supported package manager found"
        exit 1
    fi

    if command -v flatpak &>/dev/null; then
        echo ""
        if flatpak remotes 2>/dev/null | grep -q system; then
            log_info "Updating system flatpaks..."
            flatpak update -y 2>/dev/null || true
        fi
        if flatpak remotes 2>/dev/null | grep -q user; then
            log_info "Updating user flatpaks..."
            flatpak update --user -y 2>/dev/null || true
        fi
    fi

    success_box "System update complete"


[group('Maintenance')]
update-ujust:
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    elevate

    header_box "Updating ujust"

    if ! update_repo "$UJUST_REPO"; then
        error_box "Failed to update repository"
        exit 1
    fi

    success_box "ujust updated successfully!"


[group('Maintenance')]
update-all: update-ujust dotfiles-update update
    #!/bin/bash
    source "/usr/share/ujust/dotfiles/just/lib/common.sh"
    header_box "Full system update complete!"
