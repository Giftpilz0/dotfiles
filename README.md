# Dotfiles

Fedora dotfiles and workstation provisioning.
Works on **Fedora Workstation** (mutable) and **Fedora Silverblue** (rpm-ostree/immutable).

## Quickstart

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Giftpilz0/dotfiles/main/setup.sh)
```

`setup.sh` will:

1. Install missing dependencies (`chezmoi`, `ansible`, `git`) via `dnf` or `rpm-ostree`
1. Prompt to select users for Ansible provisioning and dotfiles
1. Run Ansible (packages, COPR repos, flatpaks) for each selected user
1. Deploy `chezmoi-init.service` so dotfiles are applied automatically on first login

> **Silverblue:** if new packages were layered, a reboot is required before first login.

## chezmoi workflow

```bash
chezmoi update                            # pull and apply latest dotfiles
chezmoi edit ~/.bashrc && chezmoi apply   # edit a file and apply
chezmoi cd && chezmoi re-add              # pull local changes into chezmoi repo
chezmoi diff                              # preview pending changes
```
