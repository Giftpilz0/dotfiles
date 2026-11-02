import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "projectLauncher"

    readonly property string defaultTrigger: "~"
    readonly property string defaultSearchRoot: "~"
    readonly property string defaultMaxDepth: "8"
    readonly property string defaultEditor: "flatpak run dev.zed.Zed"
    readonly property string defaultTerminal: Quickshell.env("TERMINAL") || "kitty"
    readonly property string defaultExcludes: ".cache, .var, .cargo, .rustup, .claude/plugins, node_modules, go/pkg, .local/share/containers, .local/share/Trash"

    StyledText {
        width: parent.width
        text: "Project Launcher"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Lists git repositories (found with fd). Enter opens the editor; the context menu offers a terminal, the file manager and copying the path. Requires fd."
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
        description: "Type this prefix in the launcher to search projects (default: " + defaultTrigger + ")"
        placeholder: defaultTrigger
        defaultValue: defaultTrigger
    }

    StringSetting {
        settingKey: "editor"
        label: "Editor Command"
        description: "Runs with the repository path as last argument"
        placeholder: defaultEditor
        defaultValue: defaultEditor
    }

    StringSetting {
        settingKey: "terminal"
        label: "Terminal Application"
        description: "Opened in the repository"
        placeholder: defaultTerminal
        defaultValue: defaultTerminal
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StringSetting {
        settingKey: "search_root"
        label: "Search Root"
        description: "Directory searched for repositories"
        placeholder: defaultSearchRoot
        defaultValue: defaultSearchRoot
    }

    StringSetting {
        settingKey: "max_depth"
        label: "Max Depth"
        description: "How deep below the search root to look"
        placeholder: defaultMaxDepth
        defaultValue: defaultMaxDepth
    }

    StringSetting {
        settingKey: "excludes"
        label: "Excludes"
        description: "Comma-separated fd glob patterns that are skipped"
        placeholder: defaultExcludes
        defaultValue: defaultExcludes
    }
}
