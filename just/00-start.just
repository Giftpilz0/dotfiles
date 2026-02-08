import "/usr/share/ujust/just/10-setup.just"
import "/usr/share/ujust/just/20-ansible.just"
import "/usr/share/ujust/just/30-dotfiles.just"
import "/usr/share/ujust/just/40-dms.just"
import "/usr/share/ujust/just/50-fonts.just"
import "/usr/share/ujust/just/60-dconf.just"
import "/usr/share/ujust/just/70-system.just"

[group('General')]
default:
    @ujust --list

[group('Maintenance')]
update-ujust:
    #!/bin/bash
    source "/usr/share/ujust/just/lib/common.sh"

    if ! is_root && [[ -d "/usr/share/ujust" ]]; then
        if request_root "This command updates system-wide ujust files"; then
            exec sudo ujust update-ujust
        fi
        exit 0
    fi

    show_header "Updating ujust"

    TMPDIR=$(mktemp -d)
    trap "rm -rf $TMPDIR" EXIT

    log_info "Downloading latest justfiles..."
    git clone --depth 1 https://github.com/Giftpilz0/dotfiles.git "${TMPDIR}/dotfiles" 2>/dev/null

    log_info "Installing to /usr/share/ujust/just/..."
    mkdir -p /usr/share/ujust/just/lib

    for f in "${TMPDIR}/dotfiles/just/lib/"*.sh; do
        [[ -f "$f" ]] || continue
        cp "$f" /usr/share/ujust/just/lib/
        log_info "Updated: $(basename "$f")"
    done

    for f in "${TMPDIR}/dotfiles/just/"*.just; do
        [[ -f "$f" ]] || continue
        cp "$f" /usr/share/ujust/just/
        log_info "Updated: $(basename "$f")"
    done

    show_success "ujust updated successfully!"

[group('Maintenance')]
update-all: update-ujust dotfiles-update update
    @echo ""
    @echo "======================================="
    @echo "[✔] Full system update complete!"
    @echo "======================================="
