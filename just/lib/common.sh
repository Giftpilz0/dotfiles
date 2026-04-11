#!/usr/bin/env bash
set -euo pipefail

COMMON_SH_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_UJUST_REPO="$(cd -- "${COMMON_SH_DIR}/../.." && pwd)"

export UJUST_REPO="${UJUST_REPO:-${DEFAULT_UJUST_REPO}}"
export CHEZMOI_REPO_URL="${CHEZMOI_REPO_URL:-https://github.com/Giftpilz0/dotfiles.git}"

have_gum() {
    command -v gum >/dev/null 2>&1
}

can_prompt_with_gum() {
    have_gum && [[ -t 0 && -t 1 ]]
}

_print_box() {
    local level="$1"
    local color="$2"
    local message="$3"
    local stream="${4:-stdout}"

    if have_gum; then
        if [[ "$stream" == "stderr" ]]; then
            gum style --foreground "$color" "[${level}] ${message}" >&2
        else
            gum style --foreground "$color" "[${level}] ${message}"
        fi
    elif [[ "$stream" == "stderr" ]]; then
        printf '[%s] %s\n' "$level" "$message" >&2
    else
        printf '[%s] %s\n' "$level" "$message"
    fi
}

header_box() {
    if have_gum; then
        printf '\n'
        gum style --border rounded --bold --padding '0 1' --margin '1 0 0 0' --foreground 212 "$1"
    else
        printf '\n== %s ==\n' "$1"
    fi
}

info_box() {
    _print_box "info" 81 "$1"
}

success_box() {
    _print_box "ok" 42 "$1"
}

warn_box() {
    _print_box "warn" 214 "$1" "stderr"
}

error_box() {
    _print_box "error" 196 "$1" "stderr"
}

log_info() { info_box "$1"; }

join_by() {
    local separator="$1"
    shift
    local first=true
    local item

    for item in "$@"; do
        if [[ "$first" == true ]]; then
            printf '%s' "$item"
            first=false
        else
            printf '%s%s' "$separator" "$item"
        fi
    done
}

is_root() {
    [[ "${UID:-$(id -u)}" -eq 0 ]]
}

elevate() {
    if ! is_root; then
        info_box "Elevating to root..."
        exec sudo --preserve-env=UJUST_REPO,CHEZMOI_REPO_URL,UJUST_USERS bash "$0" "$@"
    fi
}

require_command() {
    local command_name="$1"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        error_box "Required command not found: $command_name"
        return 1
    fi
}

is_bootc_system() {
    command -v bootc >/dev/null 2>&1 && [[ -f /run/ostree-booted ]]
}

uid_min() {
    awk '/^UID_MIN[[:space:]]+/ { print $2; exit }' /etc/login.defs 2>/dev/null || printf '1000\n'
}

ensure_user_exists() {
    local user="$1"

    if ! getent passwd "$user" >/dev/null 2>&1; then
        error_box "User not found: $user"
        return 1
    fi
}

get_user_home() {
    local user="$1"
    getent passwd "$user" | cut -d: -f6
}

invoking_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        printf '%s\n' "$SUDO_USER"
    else
        id -un
    fi
}

list_selectable_users() {
    local min_uid
    min_uid="$(uid_min)"

    getent passwd | while IFS=: read -r user _ uid _ _ home shell; do
        [[ "$home" == /* ]] || continue
        if [[ "$user" != "root" && "$uid" -lt "$min_uid" ]]; then
            continue
        fi
        case "$shell" in
            */nologin|*/false)
                [[ "$user" == "root" ]] || continue
                ;;
        esac
        printf '%s\n' "$user"
    done | awk 'NF && !seen[$0]++'
}

list_selectable_non_root_users() {
    list_selectable_users | awk '$0 != "root"'
}

parse_user_override() {
    if [[ -z "${UJUST_USERS:-}" ]]; then
        return 0
    fi

    printf '%s\n' "$UJUST_USERS" | tr ',' '\n' | awk '{$1=$1} NF && !seen[$0]++'
}

resolve_target_users() {
    local prompt="$1"
    local mode="${2:-any}"
    shift 2 || true
    local -a defaults=("$@")
    local -a candidates=()
    local -a selected=()
    local user
    local valid

    if [[ "$mode" == "non-root" ]]; then
        mapfile -t candidates < <(list_selectable_non_root_users)
    else
        mapfile -t candidates < <(list_selectable_users)
    fi

    if [[ ${#candidates[@]} -eq 0 ]]; then
        error_box "No selectable users found"
        return 1
    fi

    if [[ -n "${UJUST_USERS:-}" ]]; then
        mapfile -t selected < <(parse_user_override)
    elif can_prompt_with_gum && [[ ${#candidates[@]} -gt 1 ]]; then
        mapfile -t selected < <(printf '%s\n' "${candidates[@]}" | gum choose --no-limit --header "$prompt")
    else
        for user in "${defaults[@]}"; do
            [[ -n "$user" ]] && selected+=("$user")
        done
    fi

    if [[ ${#selected[@]} -eq 0 ]]; then
        error_box "No users selected"
        return 1
    fi

    local -a normalized=()
    for user in "${selected[@]}"; do
        ensure_user_exists "$user"
        if [[ "$mode" == "non-root" && "$user" == "root" ]]; then
            error_box "Ansible cannot target root; choose a non-root user instead"
            return 1
        fi

        valid=false
        local candidate
        for candidate in "${candidates[@]}"; do
            if [[ "$candidate" == "$user" ]]; then
                valid=true
                break
            fi
        done

        if [[ "$valid" != true ]]; then
            error_box "Unsupported user selection: $user"
            return 1
        fi

        if [[ ! " ${normalized[*]} " =~ (^|[[:space:]])"${user}"($|[[:space:]]) ]]; then
            normalized+=("$user")
        fi
    done

    printf '%s\n' "${normalized[@]}"
}

default_dotfile_users() {
    local user
    user="$(invoking_user)"
    if [[ "$user" == "root" ]]; then
        printf 'root\n'
    else
        printf '%s\nroot\n' "$user"
    fi
}

default_status_users() {
    default_dotfile_users
}

default_ansible_users() {
    local user
    user="$(invoking_user)"
    if [[ "$user" != "root" ]]; then
        printf '%s\n' "$user"
        return 0
    fi

    list_selectable_non_root_users | head -n 1
}

print_selected_users() {
    local -a users=("$@")
    info_box "Users: $(join_by ', ' "${users[@]}")"
}

run_as_user() {
    local user="$1"
    local user_home
    local user_runtime_dir
    shift

    ensure_user_exists "$user"
    user_home="$(get_user_home "$user")"
    user_runtime_dir="/run/user/$(id -u "$user")"

    if [[ "$user" == "root" ]]; then
        HOME="$user_home" \
        USER="$user" \
        LOGNAME="$user" \
        XDG_CONFIG_HOME="${user_home}/.config" \
        XDG_DATA_HOME="${user_home}/.local/share" \
        XDG_RUNTIME_DIR="$user_runtime_dir" \
        "$@"
    elif [[ "$user" == "$(id -un)" ]]; then
        HOME="$user_home" \
        USER="$user" \
        LOGNAME="$user" \
        XDG_RUNTIME_DIR="$user_runtime_dir" \
        "$@"
    else
        sudo -u "$user" \
            HOME="$user_home" \
            USER="$user" \
            LOGNAME="$user" \
            XDG_RUNTIME_DIR="$user_runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=${user_runtime_dir}/bus" \
            "$@"
    fi
}

run_chezmoi_as_user() {
    local user="$1"
    shift

    run_as_user "$user" "$@"
}

chezmoi_config_file_for_user() {
    local user="$1"
    printf '%s/.config/chezmoi/chezmoi.toml\n' "$(get_user_home "$user")"
}

chezmoi_source_dir_for_user() {
    local user="$1"
    printf '%s/.local/share/chezmoi\n' "$(get_user_home "$user")"
}

dotfiles_marker_file() {
    local user="$1"
    printf '%s/.local/state/ujust/dotfiles-applied\n' "$(get_user_home "$user")"
}

ensure_chezmoi_config_for_user() {
    local user="$1"
    local config_file
    local config_dir

    config_file="$(chezmoi_config_file_for_user "$user")"
    config_dir="$(dirname "$config_file")"
    run_as_user "$user" bash -lc "mkdir -p '$config_dir' && if [[ ! -f '$config_file' ]]; then printf '[data]\n    enable_dms = false\n' > '$config_file'; fi"
}

is_dotfiles_applied_for_user() {
    local user="$1"
    [[ -f "$(dotfiles_marker_file "$user")" ]]
}

is_chezmoi_initialized_for_user() {
    local user="$1"
    [[ -d "$(chezmoi_source_dir_for_user "$user")/.git" ]]
}

chezmoi_origin_for_user() {
    local user="$1"
    local source_dir

    source_dir="$(chezmoi_source_dir_for_user "$user")"
    if [[ -d "$source_dir/.git" ]]; then
        run_as_user "$user" git -C "$source_dir" remote get-url origin 2>/dev/null || true
    fi
}

sync_chezmoi_remote_for_user() {
    local user="$1"
    local source_dir

    source_dir="$(chezmoi_source_dir_for_user "$user")"
    if [[ -d "$source_dir/.git" ]] && run_as_user "$user" git -C "$source_dir" remote get-url origin >/dev/null 2>&1; then
        run_as_user "$user" git -C "$source_dir" remote set-url origin "$CHEZMOI_REPO_URL"
    fi
}

ensure_chezmoi_initialized_for_user() {
    local user="$1"

    ensure_chezmoi_config_for_user "$user"
    if is_chezmoi_initialized_for_user "$user"; then
        sync_chezmoi_remote_for_user "$user"
        return 0
    fi

    run_chezmoi_as_user "$user" chezmoi init "$CHEZMOI_REPO_URL"
    sync_chezmoi_remote_for_user "$user"
}

apply_dotfiles_for_user() {
    local user="$1"
    local user_home
    local marker_file
    local marker_dir

    ensure_user_exists "$user"
    require_command chezmoi
    user_home="$(get_user_home "$user")"
    marker_file="$(dotfiles_marker_file "$user")"
    marker_dir="$(dirname "$marker_file")"

    if [[ ! -d "$user_home" ]]; then
        error_box "Home directory not found for user: $user"
        return 1
    fi

    ensure_chezmoi_initialized_for_user "$user"
    run_as_user "$user" bash -lc "mkdir -p '$marker_dir'"
    run_chezmoi_as_user "$user" chezmoi apply --force
    run_as_user "$user" bash -lc "touch '$marker_file'"
}

update_dotfiles_for_user() {
    local user="$1"
    local marker_file

    marker_file="$(dotfiles_marker_file "$user")"
    if ! is_chezmoi_initialized_for_user "$user"; then
        apply_dotfiles_for_user "$user"
        return 0
    fi

    sync_chezmoi_remote_for_user "$user"
    run_chezmoi_as_user "$user" chezmoi update --force
    run_as_user "$user" bash -lc "mkdir -p '$(dirname "$marker_file")' && touch '$marker_file'"
}

apply_dotfiles_for_users() {
    local -a users=("$@")
    local user

    print_selected_users "${users[@]}"
    for user in "${users[@]}"; do
        info_box "Applying dotfiles for ${user}"
        apply_dotfiles_for_user "$user"
    done
}

update_dotfiles_for_users() {
    local -a users=("$@")
    local user

    print_selected_users "${users[@]}"
    for user in "${users[@]}"; do
        info_box "Updating dotfiles for ${user}"
        if is_chezmoi_initialized_for_user "$user"; then
            update_dotfiles_for_user "$user"
        else
            warn_box "Skipping ${user}: chezmoi is not initialized"
        fi
    done
}

print_dotfiles_status() {
    local user="$1"
    local origin
    local state="not applied"

    ensure_user_exists "$user"
    if is_dotfiles_applied_for_user "$user"; then
        state="applied"
    fi

    if is_chezmoi_initialized_for_user "$user"; then
        echo "  ${user}: ${state}"
        echo "    source: $(chezmoi_source_dir_for_user "$user")"
        origin="$(chezmoi_origin_for_user "$user")"
        if [[ -n "$origin" ]]; then
            echo "    origin: ${origin}"
        fi
    else
        echo "  ${user}: not initialized"
    fi
}

print_dotfiles_status_for_users() {
    local -a users=("$@")
    local user

    print_selected_users "${users[@]}"
    for user in "${users[@]}"; do
        print_dotfiles_status "$user"
    done
}

ensure_ansible_bundle() {
    if [[ ! -d "${UJUST_REPO}/ansible" ]]; then
        error_box "Ansible directory not found at ${UJUST_REPO}/ansible"
        return 1
    fi
    if [[ ! -f "${UJUST_REPO}/ansible/requirements.yml" ]]; then
        error_box "Missing Ansible requirements.yml"
        return 1
    fi
}

prepare_ansible_runtime() {
    require_command ansible-galaxy
    require_command ansible-playbook
    ensure_ansible_bundle

    cd "${UJUST_REPO}/ansible"

    COLLECTIONS_DIR="/var/lib/ujust/ansible/collections"
    install -d "${COLLECTIONS_DIR}"
    export ANSIBLE_COLLECTIONS_PATH="${COLLECTIONS_DIR}:${ANSIBLE_COLLECTIONS_PATH:-}"

    log_info "Installing required collections..."
    ansible-galaxy collection install --collections-path "${COLLECTIONS_DIR}" -r requirements.yml
}

run_ansible_for_users() {
    local -a users=("$@")
    local target_user
    local -a playbook_args

    if [[ ${#users[@]} -eq 0 ]]; then
        error_box "No non-root users selected for Ansible"
        return 1
    fi

    print_selected_users "${users[@]}"
    prepare_ansible_runtime

    for target_user in "${users[@]}"; do
        info_box "Running Ansible playbook for ${target_user}"
        playbook_args=(
            --connection=local
            play.yml
            --extra-vars "ansible_user=${target_user}"
            --extra-vars "user_username=${target_user}"
        )
        if [[ -n "${ANSIBLE_INVENTORY_OVERRIDE:-}" ]]; then
            log_info "Using overridden inventory: ${ANSIBLE_INVENTORY_OVERRIDE}"
            playbook_args=(-i "${ANSIBLE_INVENTORY_OVERRIDE}" "${playbook_args[@]}")
        fi

        ansible-playbook "${playbook_args[@]}"
    done
}

update_system() {
    if is_bootc_system; then
        require_command bootc
        log_info "Running bootc upgrade..."
        bootc upgrade
    elif command -v dnf5 >/dev/null 2>&1; then
        log_info "Running dnf5 upgrade..."
        dnf5 upgrade -y
    elif command -v dnf >/dev/null 2>&1; then
        log_info "Running dnf upgrade..."
        dnf upgrade -y
    else
        error_box "No supported package manager found"
        return 1
    fi

    if command -v flatpak >/dev/null 2>&1; then
        if flatpak remotes --system --columns=name 2>/dev/null | grep -q .; then
            log_info "Updating system flatpaks..."
            flatpak update --system -y
        fi
        if flatpak remotes --user --columns=name 2>/dev/null | grep -q .; then
            log_info "Updating user flatpaks..."
            flatpak update --user -y
        fi
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    error_box "This script should be sourced, not executed directly"
    exit 1
fi
