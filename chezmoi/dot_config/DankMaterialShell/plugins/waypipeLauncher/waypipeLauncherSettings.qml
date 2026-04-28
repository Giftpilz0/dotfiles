import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "waypipeLauncher"

    readonly property string defaultTrigger: "wp"
    readonly property string defaultWaypipeCommand: "waypipe"
    readonly property string defaultConfigPath: "~/.ssh/waypipe.yaml"

    StyledText {
        width: parent.width
        text: "Waypipe Launcher"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Reads Waypipe connections from a YAML config file. Requires python-yaml (pyyaml) to be installed."
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
        description: "Type this prefix in the launcher to search Waypipe connections (default: " + defaultTrigger + ")"
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
        text: "Command"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StringSetting {
        settingKey: "waypipe_command"
        label: "Waypipe Command"
        description: "Waypipe binary to use"
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
        settingKey: "config_path"
        label: "Waypipe Config Path"
        description: "Path to the waypipe YAML config file"
        placeholder: defaultConfigPath
        defaultValue: defaultConfigPath
    }
}
