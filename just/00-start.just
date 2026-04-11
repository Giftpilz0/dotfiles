import "./10-setup.just"
import "./20-ansible.just"
import "./30-dotfiles.just"
import "./50-system.just"

[group('General')]
default:
    @ujust --list
