#!/bin/bash
set -euo pipefail

export YOLK_DIR="${HOME}/.config/yolk"

_log() {
    level="$1"
    message="$2"
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        ERROR) echo "[${timestamp}] [✘] ${message}" >&2 ;;
        WARN)  echo "[${timestamp}] [⚠] ${message}" >&2 ;;
        INFO)  echo "[${timestamp}] [✔] ${message}" ;;
    esac
}

log_error() { _log "ERROR" "$1"; }
log_warn()  { _log "WARN"  "$1"; }
log_info()  { _log "INFO"  "$1"; }

show_header() {
    echo ""
    echo "======================================="
    echo "$1"
    echo "======================================="
    echo ""
}

show_success() {
    echo ""
    echo "======================================="
    echo "[✔] $1"
    echo "======================================="
}

show_error() {
    echo ""
    echo "=======================================" >&2
    echo "[✘] $1" >&2
    echo "=======================================" >&2
}

is_root() {
    [[ "${UID:-$(id -u)}" -eq 0 ]]
}

request_root() {
    reason="${1:-This operation requires root privileges}"

    if is_root; then
        return 0
    fi

    show_header "Root Privileges Required"
    echo "$reason"
    echo ""

    if gum confirm "Elevate to root and continue?"; then
        return 0
    else
        log_info "Cancelled by user"
        return 1
    fi
}

run_as_root() {
    if is_root; then
        "$@"
    else
        sudo "$@"
    fi
}

run_as_user() {
    user="$1"
    shift
    if [[ "$user" == "$(whoami)" ]]; then
        "$@"
    else
        # Set up environment for user services to work properly
        user_home=$(get_user_home "$user")
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$user")/bus"
        sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" "$@"
    fi
}

get_regular_users() {
    awk -F: '$3 >= 1000 && $3 < 65534 && $1 != "nobody" {print $1}' /etc/passwd
}

get_user_home() {
    user="$1"
    getent passwd "$user" | cut -d: -f6
}

check_command() {
    command -v "$1" &>/dev/null
}

is_package_installed() {
    pkg="$1"
    rpm -q "$pkg" &>/dev/null || return 1
}

service_exists() {
    service="$1"
    scope="${2:-system}"

    if [[ "$scope" == "user" ]]; then
        systemctl --user list-unit-files "${service}.service" &>/dev/null
    else
        systemctl list-unit-files "${service}.service" &>/dev/null
    fi
}

enable_service() {
    service="$1"
    scope="${2:-system}"

    if ! service_exists "$service" "$scope"; then
        return 0
    fi

    if [[ "$scope" == "user" ]]; then
        systemctl --user enable "$service" 2>/dev/null || true
    else
        run_as_root systemctl enable "$service" 2>/dev/null || true
    fi
}

disable_service() {
    service="$1"
    scope="${2:-system}"

    if ! service_exists "$service" "$scope"; then
        return 0
    fi

    if [[ "$scope" == "user" ]]; then
        systemctl --user disable "$service" 2>/dev/null || true
    else
        run_as_root systemctl disable "$service" 2>/dev/null || true
    fi
}

is_service_enabled() {
    service="$1"
    scope="${2:-system}"

    if [[ "$scope" == "user" ]]; then
        systemctl --user is-enabled "$service" &>/dev/null
    else
        systemctl is-enabled "$service" &>/dev/null
    fi
}

is_dms_installed() {
    is_package_installed dms
}

is_dms_copr_enabled() {
    dnf copr list 2>/dev/null | grep -q "avengemedia/dms"
}

configure_dms() {
    use_dms="$1"
    config_file="${HOME}/.config/yolk/eggs/niri/config.kdl"

    [[ ! -f "$config_file" ]] && return 0

    if [[ "$use_dms" == "true" ]]; then
        sed -i '/misc\/dms\.kdl/s/^\/\/* *//; /misc\/nodms\.kdl/s/^ *\(\/\/\)* */\/\/ /' "$config_file"
    else
        sed -i '/misc\/dms\.kdl/s/^ *\(\/\/\)* */\/\/ /; /misc\/nodms\.kdl/s/^\/\/* *//g' "$config_file"
    fi
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

manage_dms_services() {
    active="$1"

    if [[ "$active" == "true" ]]; then
        enable_service "dms" "user"
        enable_service "dsearch" "user"
    else
        disable_service "dms" "user"
        disable_service "dsearch" "user"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_error "This script should be sourced, not executed directly"
    exit 1
fi
