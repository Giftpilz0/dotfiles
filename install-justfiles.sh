#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
COMMON_SH=""
for candidate in \
    "${SCRIPT_DIR}/just/lib/common.sh" \
    "/usr/share/ujust/just/lib/common.sh"
do
    if [[ -f "${candidate}" ]]; then
        COMMON_SH="${candidate}"
        break
    fi
done

if [[ -n "${COMMON_SH}" ]]; then
    source "${COMMON_SH}"
fi

show_error() {
    printf '[error] %s\n' "$1" >&2
}

show_info() {
    printf '[info] %s\n' "$1"
}

show_success() {
    printf '[ok] %s\n' "$1"
}

elevate_local() {
    if declare -F elevate >/dev/null 2>&1; then
        elevate "$@"
    elif [[ "${UID}" -ne 0 ]]; then
        show_info "Elevating to root..."
        exec sudo bash "$0" "$@"
    fi
}

is_bootc_system_local() {
    if declare -F is_bootc_system >/dev/null 2>&1; then
        is_bootc_system
    else
        command -v bootc >/dev/null 2>&1 && [[ -f /run/ostree-booted ]]
    fi
}

check_deps() {
    local deps=("ansible" "chezmoi" "curl" "dconf" "fontconfig" "git" "gum" "jq" "just" "rsync" "unzip")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1 && ! rpm -q "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        show_success "All dependencies already installed"
        return 0
    fi

    if is_bootc_system_local; then
        show_error "Missing dependencies on a bootc system: ${missing[*]}"
        show_error "Install them in the image instead of layering them at runtime."
        exit 1
    fi

    show_info "Installing missing dependencies: ${missing[*]}"
    if command -v dnf5 >/dev/null 2>&1; then
        dnf5 install -y "${missing[@]}"
    else
        dnf install -y "${missing[@]}"
    fi
}

run_chezmoi_bootstrap() {
    local user="$1"
    local repo_url="${CHEZMOI_REPO_URL:-https://github.com/Giftpilz0/dotfiles.git}"

    if declare -F apply_dotfiles_for_user >/dev/null 2>&1; then
        apply_dotfiles_for_user "$user"
        return 0
    fi

    if [[ "$user" == "root" ]]; then
        HOME=/root \
        XDG_CONFIG_HOME=/root/.config \
        XDG_DATA_HOME=/root/.local/share \
        chezmoi init --apply "${repo_url}"
        install -d /root/.local/state/ujust
        touch /root/.local/state/ujust/dotfiles-applied
        return 0
    fi

    local target_uid
    local target_runtime_dir
    target_uid="$(id -u "$user")"
    target_runtime_dir="/run/user/${target_uid}"

    sudo -u "$user" \
        XDG_RUNTIME_DIR="${target_runtime_dir}" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=${target_runtime_dir}/bus" \
        chezmoi init --apply "${repo_url}"
}

APPLY_ROOT=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply-root)
            APPLY_ROOT=true
            ;;
        *)
            show_error "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

elevate_local "$@"

printf '== %s ==\n' "ujust bootstrap"
check_deps

if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    show_info "Bootstrapping chezmoi for ${SUDO_USER}..."
    run_chezmoi_bootstrap "${SUDO_USER}"
elif [[ "$APPLY_ROOT" != "true" ]]; then
    show_error "Run this script via sudo from the target user account, or pass --apply-root for a root-only bootstrap."
    exit 1
fi

if [[ "$APPLY_ROOT" == "true" ]]; then
    show_info "Bootstrapping chezmoi for root..."
    run_chezmoi_bootstrap root
fi

show_success "chezmoi bootstrap complete"
show_info "Open a new shell so ~/.local/bin/ujust is on PATH"
