#!/bin/bash
set -euo pipefail

show_error() {
    gum style --border rounded --border-foreground 9 --foreground 9 "✘ $1" >&2
}

show_info() {
    gum style --border rounded --foreground 12 "$1"
}

show_success() {
    gum style --border rounded --border-foreground 10 --foreground 10 "✔ $1"
}

elevate() {
    if [[ "${UID}" -ne 0 ]]; then
        show_info "Elevating to root..."
        exec sudo bash "$0" "$@"
    fi
}

check_deps() {
    deps=("just" "gum" "git" "curl" "jq" "fontconfig" "unzip")
    missing=()

    for dep in "${deps[@]}"; do
        if ! rpm -q "$dep" &>/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        show_info "Installing missing dependencies: ${missing[*]}"
        dnf install -y "${missing[@]}"
    else
        show_success "All dependencies already installed"
    fi
}


install_ujust() {
    mkdir -p "/usr/share/ujust"
    mkdir -p "/usr/local/bin"

    DOTFILES_DIR="/usr/share/ujust/dotfiles"

    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        show_info "Updating existing repository..."
        (cd "$DOTFILES_DIR" && git pull --rebase --autostash 2>/dev/null) || true
    else
        show_info "Cloning repository..."
        git clone "https://github.com/Giftpilz0/dotfiles.git" "$DOTFILES_DIR" 2>/dev/null
    fi

    cat > "/usr/local/bin/ujust" << 'EOF'
#!/bin/bash
set -euo pipefail

if [[ -d "/usr/share/ujust/dotfiles/.git" ]]; then
    (cd "/usr/share/ujust/dotfiles" && git pull --rebase --autostash 2>/dev/null) || true
fi

exec just -f "/usr/share/ujust/dotfiles/just/00-start.just" "$@"
EOF

    chmod +x "/usr/local/bin/ujust"

    mkdir -p /usr/share/bash-completion/completions /usr/share/zsh/site-functions /usr/share/fish/vendor_completions.d/
    just --completions bash 2>/dev/null | sed -E 's/([\(_" ])just/\1ujust/g' > /usr/share/bash-completion/completions/ujust 2>/dev/null || true
    just --completions zsh 2>/dev/null | sed -E 's/([\(_" ])just/\1ujust/g' > /usr/share/zsh/site-functions/_ujust 2>/dev/null || true
    just --completions fish 2>/dev/null | sed -E 's/([\(_" ])just/\1ujust/g' > /usr/share/fish/vendor_completions.d/ujust.fish 2>/dev/null || true
}

elevate "$@"

gum style --border double --align center --width 50 --margin "1 0" \
    "ujust Installer"

check_deps
install_ujust

show_success "ujust installed successfully"
show_info "Starting setup..."

exec ujust setup
