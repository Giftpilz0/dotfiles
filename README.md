# Fedora bootc niri

Personal Fedora bootc workstation image and dotfiles.

## Quickstart

Apply the current user's dotfiles:

```bash
chezmoi init --apply https://github.com/Giftpilz0/dotfiles.git
```

Apply the same dotfiles for `root` too:

```bash
curl -fsSL https://raw.githubusercontent.com/Giftpilz0/dotfiles/main/install-justfiles.sh | sudo bash -s -- --apply-root
```

Useful `ujust` commands:

```bash
ujust --list
ujust setup
ujust status
ujust update
ujust ansible-apply
ujust dotfiles-apply
ujust dotfiles-update
```

`ujust` uses `gum` for prettier output and, in an interactive terminal, lets you choose which users a command should target.

`ujust setup` runs local Ansible for the selected non-root users and applies dotfiles for the selected users.

## Chezmoi workflow

Check what changed:

```bash
chezmoi status
chezmoi diff
```

Update from the repo and reapply:

```bash
chezmoi update
```

Edit and apply local changes:

```bash
chezmoi edit ~/.bashrc
chezmoi apply
```

Push your dotfile changes:

```bash
chezmoi cd
git status
git add .
git commit -m "Update dotfiles"
git push
```

## Bootc behavior

- the image build applies the root dotfiles and the system dconf/background settings during the image build
- new non-root users get dotfiles on first login through the user service `ujust-dotfiles-apply.service`
- `root` also gets a normal chezmoi source dir and config in the image, so root can inspect and update dotfiles like any other user
- external tools managed by chezmoi, such as `yazi` and `sysutil`, are downloaded by chezmoi at apply/update time instead of being pre-staged into the image

## Repository layout

- `chezmoi/` - user and root dotfiles
- `ansible/` - local provisioning
- `just/` - `ujust` commands
- `fedora-bootc-niri/` - mkosi bootc image

## Build the image

Requirements:

- `podman`
- `just`
- `mkosi >= 26`

Commands:

```bash
just config
just build
just load
just lint
just installer-iso
```

`just build` regenerates the mkosi package content from `ansible/vars/package-manifest.json` before mkosi runs.

The installer ISO is built from `fedora-bootc-niri/disk_config/iso.toml`. Storage and user creation stay interactive in Anaconda, and `%post` switches the installed system to `ghcr.io/giftpilz0/fedora-bootc-niri:latest`.

## Notes

- Fedora target: `44`
- Root filesystem default: `btrfs`
