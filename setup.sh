#!/usr/bin/env bash
# setup.sh — Fedora workstation provisioning
# Installs dependencies, runs Ansible, and deploys chezmoi-init service for selected users.
set -euo pipefail

REPO_URL="${CHEZMOI_REPO_URL:-https://github.com/Giftpilz0/dotfiles.git}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# ── helpers ───────────────────────────────────────────────────────────────────

die()  { printf '\n[error] %s\n' "$*" >&2; exit 1; }
info() { printf '[info]  %s\n' "$*"; }
ok()   { printf '[ok]    %s\n' "$*"; }
hr()   { printf '\n── %s ──\n\n' "$*"; }

ask_yn() {
    local prompt="$1" default="${2:-y}"
    local yn_hint
    [[ "$default" == y ]] && yn_hint="[Y/n]" || yn_hint="[y/N]"
    local reply
    read -r -p "$prompt $yn_hint " reply
    reply="${reply:-$default}"
    [[ "${reply,,}" == y ]]
}

# ── elevation ─────────────────────────────────────────────────────────────────

if [[ "${UID}" -ne 0 ]]; then
    info "Elevating to root…"
    exec sudo --preserve-env=CHEZMOI_REPO_URL bash "$0" "$@"
fi

INVOKING_USER="${SUDO_USER:-}"

# ── system detection ──────────────────────────────────────────────────────────

is_ostree() { [[ -f /run/ostree-booted ]]; }

# ── dependency installation ───────────────────────────────────────────────────

install_deps() {
    local -a deps=(chezmoi ansible git)
    local -a missing=()
    local dep
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
    done
    [[ ${#missing[@]} -eq 0 ]] && { ok "Dependencies already installed"; return 0; }

    info "Installing: ${missing[*]}"
    if is_ostree; then
        rpm-ostree install -y "${missing[@]}" \
            || die "rpm-ostree install failed — reboot and re-run setup.sh"
        info "Installed via rpm-ostree. A reboot may be required before continuing."
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y "${missing[@]}"
    else
        die "No supported package manager found"
    fi
}

# ── user helpers ──────────────────────────────────────────────────────────────

list_human_users() {
    local min
    min="$(awk '/^UID_MIN[[:space:]]+/ { print $2; exit }' /etc/login.defs 2>/dev/null || echo 1000)"
    getent passwd | awk -F: -v min="$min" \
        '$3 >= min && $7 !~ /nologin|false/ && $6 ~ /^\// { print $1 }' | sort
}

get_user_home() { getent passwd "$1" | cut -d: -f6; }

select_users() {
    local prompt="$1"
    local -n _result="$2"
    local -a candidates
    mapfile -t candidates < <(list_human_users)
    [[ ${#candidates[@]} -eq 0 ]] && die "No human users found on this system"

    printf '%s\n' "$prompt"
    local i
    for i in "${!candidates[@]}"; do
        printf '  %d) %s\n' "$((i + 1))" "${candidates[$i]}"
    done
    printf '  0) Skip\n\n'

    local input
    read -r -p "Enter numbers (space-separated, or 0 to skip): " input
    printf '\n'

    _result=()
    local idx
    for idx in $input; do
        [[ "$idx" == "0" ]] && return 0
        if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx >= 1 && idx <= ${#candidates[@]} )); then
            local u="${candidates[$((idx - 1))]}"
            [[ " ${_result[*]:-} " != *" $u "* ]] && _result+=("$u")
        fi
    done
}

# ── ansible ───────────────────────────────────────────────────────────────────

run_ansible() {
    info "Installing Ansible collections…"
    ansible-galaxy collection install \
        -r "${SCRIPT_DIR}/ansible/requirements.yml"

    info "Running Ansible playbook…"
    cd "${SCRIPT_DIR}/ansible"
    ansible-playbook --connection=local play.yml "$@"
}

# ── dotfiles service ──────────────────────────────────────────────────────────

deploy_dotfiles_service() {
    local user="$1"
    local user_home uid
    user_home="$(get_user_home "$user")"
    uid="$(id -u "$user")"

    local service_dir="${user_home}/.config/systemd/user"
    local wants_dir="${service_dir}/default.target.wants"
    install -d -m 0755 -o "$user" -g "$user" "$service_dir" "$wants_dir"

    local service_file="${service_dir}/chezmoi-init.service"
    cat > "$service_file" << UNIT
[Unit]
Description=Initialise dotfiles via chezmoi (first login)
ConditionPathExists=!%h/.local/share/chezmoi/.git

[Service]
Type=oneshot
ExecStart=/usr/bin/chezmoi init --apply --force ${REPO_URL}
RemainAfterExit=yes

[Install]
WantedBy=default.target
UNIT
    chmod 0644 "$service_file"
    chown "${uid}:${uid}" "$service_file"

    local symlink="${wants_dir}/chezmoi-init.service"
    ln -sf "../chezmoi-init.service" "$symlink"
    chown -h "${uid}:${uid}" "$symlink"

    ok "Dotfiles service deployed for ${user}"
}

# ── main ──────────────────────────────────────────────────────────────────────

hr "Fedora workstation setup"
printf 'Dotfiles repo: %s\n\n' "$REPO_URL"

# 1. Dependencies
hr "Dependencies"
install_deps

# 2. Select users
hr "User selection"
declare -a selected_users=()

if [[ -n "$INVOKING_USER" && "$INVOKING_USER" != "root" ]]; then
    selected_users=("$INVOKING_USER")
    printf 'Default user: %s\n\n' "$INVOKING_USER"
    if ask_yn "Set up additional users as well?" n; then
        declare -a extra_users=()
        select_users "Select additional users:" extra_users
        selected_users+=("${extra_users[@]:-}")
    fi
else
    select_users "Select users to set up:" selected_users
fi

[[ ${#selected_users[@]} -eq 0 ]] && die "No users selected"
printf 'Selected users: %s\n' "${selected_users[*]}"

# 3. Options
hr "Options"
run_ansible_flag=false
ask_yn "Run Ansible package provisioning?" && run_ansible_flag=true

# 4. Ansible
if $run_ansible_flag; then
    hr "Ansible provisioning"
    run_ansible --extra-vars "user_username=${selected_users[0]}"
    ok "Ansible complete"
fi

# 5. Deploy per-user dotfiles service
hr "Deploying dotfiles"
for user in "${selected_users[@]}"; do
    deploy_dotfiles_service "$user"
done

hr "Done"
ok "Setup complete."
printf '\nNext steps:\n'
printf '  • Log out and back in — dotfiles will be applied automatically on first login\n'
printf '  • Or apply immediately: sudo -u USER chezmoi init --apply --force %s\n' "$REPO_URL"
is_ostree && printf '  • Silverblue: if packages were layered, a reboot is required first\n'
printf '\n'
