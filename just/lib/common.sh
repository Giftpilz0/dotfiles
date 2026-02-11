#!/bin/bash
set -euo pipefail

export UJUST_REPO="/usr/share/ujust/dotfiles"
export YOLK_DIR="$UJUST_REPO"

# Gum Styling Functions
header_box() {
    gum style --border double --align center --width 50 --margin "1 0" "$1"
}

info_box() {
    gum style --border rounded --foreground 12 "$1"
}

success_box() {
    gum style --border rounded --border-foreground 10 --foreground 10 "✔ $1"
}

warn_box() {
    gum style --border rounded --border-foreground 11 --foreground 11 "⚠ $1"
}

error_box() {
    gum style --border rounded --border-foreground 9 --foreground 9 "✘ $1" >&2
}

# Logging
log_info() { info_box "$1"; }
log_warn() { warn_box "$1"; }
log_error() { error_box "$1"; }

# Permission Functions
is_root() {
    [[ "${UID:-$(id -u)}" -eq 0 ]]
}

elevate() {
    if ! is_root; then
        info_box "Elevating to root..."
        exec sudo bash "$0" "$@"
    fi
}

# User Functions
get_regular_users() {
    awk -F: '$3 >= 1000 && $3 < 65534 && $1 != "nobody" {print $1}' /etc/passwd
}

get_all_users() {
    local regular_users
    regular_users=$(get_regular_users)
    if [[ -n "$regular_users" ]]; then
        echo -e "${regular_users}\nroot"
    else
        echo "root"
    fi
}

get_user_home() {
    user="$1"
    getent passwd "$user" | cut -d: -f6
}

select_users() {
    prompt="${1:-Select users (space to select, enter to confirm):}"
    local all_users
    all_users=$(get_all_users)

    if [[ -z "$all_users" ]]; then
        error_box "No users found"
        return 1
    fi

    echo "$all_users" | gum choose --no-limit --header "$prompt"
}

# Execution Functions
run_as_user() {
    user="$1"
    shift
    if [[ "$user" == "$(whoami)" ]]; then
        "$@"
    else
        user_home=$(get_user_home "$user")
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$user")/bus"
        sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" "$@"
    fi
}

# Repository Update Function
update_repo() {
    repo_dir="${1:-$UJUST_REPO}"

    if [[ ! -d "$repo_dir/.git" ]]; then
        error_box "Repository not found at $repo_dir"
        return 1
    fi

    info_box "Updating repository..."

    (cd "$repo_dir" && git pull --rebase --autostash 2>/dev/null) || {
        warn_box "Failed to update repository, continuing with current version"
        return 0
    }

    success_box "Repository updated"
}

# Utility Functions
check_command() {
    command -v "$1" &>/dev/null
}

is_package_installed() {
    pkg="$1"
    rpm -q "$pkg" &>/dev/null || return 1
}

# Font Check
are_maple_fonts_installed() {
    font_dir="/usr/share/fonts"
    [[ -d "${font_dir}/Maple Mono Variable" ]] && [[ -d "${font_dir}/Maple Mono NF" ]]
}

# DMS Functions
is_dms_installed() {
    is_package_installed dms
}

is_dms_copr_enabled() {
    dnf copr list 2>/dev/null | grep -q "avengemedia/dms"
}

configure_dms_for_user() {
    user="$1"
    use_dms="$2"
    user_home=$(getent passwd "$user" | cut -d: -f6)
    config_file="$user_home/.config/yolk/eggs/niri/config.kdl"

    [[ ! -f "$config_file" ]] && return 0

    if [[ "$use_dms" == "true" ]]; then
        sed -i '/misc\/dms\.kdl/s/^\/\/* *//; /misc\/nodms\.kdl/s/^ *\(\/\/\)* */\/\/ /' "$config_file"
    else
        sed -i '/misc\/dms\.kdl/s/^ *\(\/\/\)* */\/\/ /; /misc\/nodms\.kdl/s/^\/\/* *//g' "$config_file"
    fi
}

# Gum Menu Helper
show_menu() {
    header="$1"
    shift
    gum choose --header "$header" "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    error_box "This script should be sourced, not executed directly"
    exit 1
fi
