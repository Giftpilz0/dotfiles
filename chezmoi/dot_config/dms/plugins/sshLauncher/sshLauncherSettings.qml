import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "sshLauncher"

    readonly property string defaultTrigger: "ssh"
    readonly property string defaultTerminal: Quickshell.env("TERMINAL") || "kitty"
    readonly property string defaultSshCommand: "ssh"
    readonly property string defaultSshConfigPath: "~/.ssh/config"
    readonly property string defaultSshTerm: "xterm-256color"
    readonly property string defaultWaypipeCommand: "waypipe"

    StyledText {
        width: parent.width
        text: "SSH Launcher"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Reads hosts from ~/.ssh/config, including Include files. Comments inside a Host block add extra users ('# fuzzel-users: root, admin'), waypipe apps ('# waypipe: firefox', repeatable) and waypipe options ('# waypipe-args: -c zstd=15')."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StringSetting {
        settingKey: "trigger"
        label: "Trigger Prefix"
        description: "Type this prefix in the launcher to search SSH connections (default: " + defaultTrigger + ")"
        placeholder: defaultTrigger
        defaultValue: defaultTrigger
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        width: parent.width
        text: "Terminal & Commands"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StringSetting {
        settingKey: "terminal"
        label: "Terminal Application"
        description: "Terminal used to open SSH sessions (e.g. kitty, alacritty, foot). '-e' is appended automatically unless already present."
        placeholder: defaultTerminal
        defaultValue: defaultTerminal
    }

    StringSetting {
        settingKey: "ssh_command"
        label: "SSH Command"
        description: "SSH command to run (e.g. 'ssh' or 'kitten ssh')"
        placeholder: defaultSshCommand
        defaultValue: defaultSshCommand
    }

    StringSetting {
        settingKey: "ssh_term"
        label: "TERM Override"
        description: "TERM env var set for SSH sessions (default: xterm-256color). Avoids broken prompts when the remote lacks your local terminal's terminfo. Leave empty to keep your TERM."
        placeholder: defaultSshTerm
        defaultValue: defaultSshTerm
    }

    StringSetting {
        settingKey: "waypipe_command"
        label: "Waypipe Command"
        description: "Waypipe binary used for '# waypipe:' apps"
        placeholder: defaultWaypipeCommand
        defaultValue: defaultWaypipeCommand
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        width: parent.width
        text: "Config File"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StringSetting {
        settingKey: "ssh_config_path"
        label: "SSH Config Path"
        description: "Path to SSH config file"
        placeholder: defaultSshConfigPath
        defaultValue: defaultSshConfigPath
    }
}
