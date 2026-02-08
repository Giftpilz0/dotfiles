#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/Giftpilz0/dotfiles.git"
INSTALL_DIR="/usr/share/ujust"
BIN_DIR="/usr/local/bin"
REPO_DIR=""

elevate() {
    if [[ "${UID}" -ne 0 ]]; then
        echo "Elevating to root..."
        exec sudo bash "$0" "$@"
    fi
}

check_deps() {
    DEPS=("just" "gum" "git" "curl" "jq" "fontconfig" "unzip")
    MISSING=()

    for dep in "${DEPS[@]}"; do
        if ! rpm -q "$dep" &>/dev/null 2>&1; then
            MISSING+=("$dep")
        fi
    done

    if [[ ${#MISSING[@]} -gt 0 ]]; then
        echo "Installing missing dependencies: ${MISSING[*]}"
        dnf install -y "${MISSING[@]}"
    else
        echo "All dependencies already installed"
    fi
}

detect_repo() {
    if git rev-parse --git-dir &>/dev/null; then
        REPO_DIR=$(git rev-parse --show-toplevel)
        echo "Using local repository"
    else
        REPO_DIR=$(mktemp -d)
        git clone --depth 1 "$REPO_URL" "$REPO_DIR" 2>/dev/null
    fi
}

install_ujust() {
    mkdir -p "$INSTALL_DIR/just/lib"
    mkdir -p "$BIN_DIR"

    JUSTFILE_SRC="$REPO_DIR/just"

    cp "$JUSTFILE_SRC/lib/"* "$INSTALL_DIR/just/lib/"
    cp "$JUSTFILE_SRC/"*.just "$INSTALL_DIR/just/"

    cat > "$BIN_DIR/ujust" << 'EOF'
#!/bin/bash
set -euo pipefail
exec just -f "/usr/share/ujust/just/00-start.just" "$@"
EOF

    chmod +x "$BIN_DIR/ujust"

    mkdir -p /usr/share/bash-completion/completions /usr/share/zsh/site-functions /usr/share/fish/vendor_completions.d/

    just --completions bash 2>/dev/null | sed -E 's/([\(_" ])just/\1ujust/g' > /usr/share/bash-completion/completions/ujust 2>/dev/null || true
    just --completions zsh 2>/dev/null | sed -E 's/([\(_" ])just/\1ujust/g' > /usr/share/zsh/site-functions/_ujust 2>/dev/null || true
    just --completions fish 2>/dev/null | sed -E 's/([\(_" ])just/\1ujust/g' > /usr/share/fish/vendor_completions.d/ujust.fish 2>/dev/null || true
}

elevate "$@"

echo "======================================="
echo "ujust Installer"
echo "======================================="
echo ""

detect_repo
check_deps
install_ujust

if [[ "$REPO_DIR" == /tmp/* ]]; then
    rm -rf "$REPO_DIR"
fi

echo ""
echo "[✔] ujust installed successfully"
echo ""
echo "Starting setup..."
echo ""

exec ujust setup
