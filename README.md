# dotfiles

[![ci](https://github.com/Giftpilz0/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/Giftpilz0/dotfiles/actions/workflows/ci.yml)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Fedora Workstation dotfiles (niri + DankMaterialShell) and provisioning, with chezmoi and Ansible.

## Usage

```sh
sudo dnf install -y chezmoi
chezmoi init --apply https://github.com/Giftpilz0/dotfiles.git
```

- The first init asks for git name, email and whether to install [razerctl](https://github.com/Giftpilz0/razerctl);
  change the answers with `chezmoi init --prompt`.
- Every apply offers to run the Ansible playbook in `ansible/` (packages, COPR repos, system config).
- Colors come from the wallpaper (DMS/matugen); the `create_*` color files are only written on a fresh machine.
- After `ya pkg add` or `ya pkg upgrade`, run `chezmoi re-add ~/.config/yazi/package.toml`.
- `~/.claude/CLAUDE.md` imports the shared guidelines, cloned to `~/.local/share/giftpilz0-shared`.

## Development

`just deploy` applies this checkout. Run `just` for all recipes and `just check` before committing. Conventions: [Giftpilz0/shared](https://github.com/Giftpilz0/shared).

## License

[MIT](LICENSE), except the images in `chezmoi/dot_config/wallpapers/`.
