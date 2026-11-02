import Quickshell
import Quickshell.Io
import QtQuick
import qs.Services

QtObject {
    id: root

    readonly property string pluginId: "projectLauncher"
    property var pluginService: null
    property string trigger: defaultTrigger
    signal itemsChanged()

    readonly property string home: Quickshell.env("HOME")
    readonly property string defaultTrigger: "~"
    readonly property string defaultSearchRoot: "~"
    readonly property string defaultMaxDepth: "8"
    readonly property string defaultEditor: "flatpak run dev.zed.Zed"
    readonly property string defaultTerminal: Quickshell.env("TERMINAL") || "kitty"
    readonly property string defaultExcludes: ".cache, .var, .cargo, .rustup, .claude/plugins, node_modules, go/pkg, .local/share/containers, .local/share/Trash"

    property string searchRoot: defaultSearchRoot
    property string maxDepth: defaultMaxDepth
    property string editor: defaultEditor
    property string terminal: defaultTerminal
    property string excludes: defaultExcludes

    property var projects: []
    property real _lastScan: 0

    property Process _scanner: Process {
        command: {
            const argv = ["fd", "--hidden", "--no-ignore", "--one-file-system", "--prune",
                          "--type", "d", "--type", "f", "--max-depth", root.maxDepth]
            for (const e of root.excludes.split(",").map(s => s.trim()).filter(s => s))
                argv.push("--exclude", e)
            argv.push("^\\.git$", root._expand(root.searchRoot))
            return argv
        }
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const dirs = text.split("\n").map(l => l.replace(/\/?\.git\/?$/, "")).filter(d => d)
                root.projects = dirs.sort((a, b) => root._base(a).localeCompare(root._base(b)))
                root.pluginService?.requestLauncherUpdate(root.pluginId)
            }
        }
        stderr: SplitParser {
            onRead: line => { if (line.trim()) console.warn(root.pluginId + ": " + line) }
        }
    }

    property Connections _settingsWatcher: Connections {
        target: root.pluginService
        function onPluginDataChanged(changedId) {
            if (changedId === root.pluginId)
                root._loadSettings()
        }
    }

    Component.onCompleted: _loadSettings()

    function getItems(query) {
        if (!query)
            _refresh(false)
        return projects.map(path => ({
            path: path,
            name: _base(path),
            icon: "material:code",
            comment: _pretty(path),
            keywords: [_pretty(path)],
            action: "project:" + path,
            categories: ["Projects"]
        }))
    }

    function executeItem(item) {
        if (item?.path)
            _openEditor(item.path)
    }

    function getContextMenuActions(item) {
        if (!item?.path)
            return []
        const path = item.path
        return [
            { icon: "edit", text: "Open in editor", action: () => root._openEditor(path) },
            { icon: "terminal", text: "Open terminal here", action: () => root._run(root._words(root.terminal), path) },
            { icon: "folder_open", text: "Open in file manager", action: () => root._run(["xdg-open", path], path) },
            { icon: "content_copy", text: "Copy path", action: () => Quickshell.execDetached(["dms", "cl", "copy", path]) },
            { icon: "refresh", text: "Rescan projects", action: () => root._refresh(true) }
        ]
    }

    function _loadSettings() {
        if (!pluginService)
            return
        const load = (key, def) => pluginService.loadPluginData(pluginId, key, def) || def
        trigger = pluginService.loadPluginData(pluginId, "trigger", defaultTrigger)
        searchRoot = load("search_root", defaultSearchRoot)
        maxDepth = load("max_depth", defaultMaxDepth)
        editor = load("editor", defaultEditor)
        terminal = load("terminal", defaultTerminal)
        excludes = pluginService.loadPluginData(pluginId, "excludes", defaultExcludes)
        _refresh(true)
    }

    function _refresh(force) {
        if (_scanner.running)
            return
        if (!force && Date.now() - _lastScan < 60000)
            return
        _lastScan = Date.now()
        _scanner.running = true
    }

    function _expand(p) {
        return p === "~" || p.startsWith("~/") ? home + p.substring(1) : p
    }

    function _pretty(p) {
        return p === home || p.startsWith(home + "/") ? "~" + p.substring(home.length) : p
    }

    function _base(p) {
        return p.substring(p.lastIndexOf("/") + 1)
    }

    function _words(s) {
        return (s || "").split(/\s+/).filter(w => w)
    }

    function _run(argv, dir) {
        console.info(pluginId + ": " + argv.join(" ") + " (in " + dir + ")")
        Quickshell.execDetached({ command: argv, workingDirectory: dir })
    }

    function _openEditor(path) {
        _run(_words(editor).concat(path), path)
    }
}
