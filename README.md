# Dotfiles

Dotfiles and bootc image for Niri.

[![Ansible-Lint](https://github.com/giftpilz0/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/giftpilz0/dotfiles/actions)

## Quick Start

### Install

```bash
curl -sL https://raw.githubusercontent.com/Giftpilz0/dotfiles/main/install-justfiles.sh | sudo bash
ujust setup
```

### Build Bootc Image

```bash
# Build container image
just build

# Build bootable ISO
just build-iso
```

## Available Commands

### Setup

```bash
ujust setup                    # Interactive system setup
ujust setup-status             # Check setup status
```

### System Management

```bash
ujust --list                   # Show all available commands
ujust update                   # Update system packages (bootc/dnf + flatpak)
ujust update-all               # Update ujust + dotfiles + system
ujust update-ujust             # Update ujust to latest version
ujust toggle-auto-update       # Toggle automatic system updates
```

### Dotfiles Management

```bash
ujust dotfiles-setup           # Deploy dotfiles for users (interactive)
ujust dotfiles-update          # Sync dotfiles from Git for all users
ujust dotfiles-status          # Check dotfiles status
```

### Font Installation

```bash
ujust fonts-setup              # Install or remove Maple Mono fonts (interactive)
ujust fonts-status             # Check font status
```

### Ansible Provisioning

```bash
ujust ansible-bootstrap        # Run Ansible bootstrap
ujust ansible-status           # Check Ansible status
```

### DMS (DankMaterialShell)

```bash
ujust dms-setup                # Install/uninstall/enable/disable DMS (interactive)
ujust dms-status               # Check DMS status
```

### DConf Management

```bash
ujust dconf-setup              # Apply dconf settings for all users
ujust dconf-update             # Re-apply dconf settings
ujust dconf-status             # Check dconf status
```

## Bootc Image

### Rebase from Existing System

```bash
sudo bootc switch --transport registry ghcr.io/giftpilz0/ublue-niri:latest
```

## Documentation

For detailed Ansible variable documentation:
https://giftpilz0.nixpi.de/docs/category/ansible-1
