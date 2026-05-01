# Dotfiles

Fedora dotfiles and workstation provisioning.
Works on **Fedora Workstation** (mutable) and **Fedora Silverblue** (rpm-ostree/immutable).

## Quickstart

### 1. Install chezmoi

**Fedora Workstation:**

```bash
sudo dnf install -y chezmoi
```

**Fedora Silverblue:**

```bash
rpm-ostree install chezmoi && systemctl reboot
```

### 2. Apply dotfiles

```bash
chezmoi init --apply https://github.com/Giftpilz0/dotfiles.git
```

chezmoi will prompt whether to run the Ansible playbook (package installation, COPR repos, system configuration).
Ansible itself will be installed automatically if missing.

> **Silverblue:** if Ansible installs packages via `rpm-ostree`, a reboot is required — then re-run `chezmoi apply`.

## chezmoi workflow

```bash
chezmoi update                            # pull and apply latest dotfiles
chezmoi edit ~/.bashrc && chezmoi apply   # edit a file and apply
chezmoi cd && chezmoi re-add              # pull local changes into chezmoi repo
chezmoi diff                              # preview pending changes
```
