# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# ujust completion
if command -v ujust &>/dev/null; then
    source <(ujust --completions bash 2>/dev/null) 2>/dev/null || true
fi
