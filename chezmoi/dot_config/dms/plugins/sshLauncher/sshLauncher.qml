import Quickshell
import Quickshell.Io
import QtQuick
import qs.Services

QtObject {
    id: root

    readonly property string pluginId: "sshLauncher"
    property var pluginService: null
    property string trigger: defaultTrigger
    signal itemsChanged()

    readonly property string defaultTrigger: "ssh"
    readonly property string defaultTerminal: Quickshell.env("TERMINAL") || "kitty"
    readonly property string defaultSshCommand: "ssh"
    readonly property string defaultSshConfigPath: "~/.ssh/config"
    readonly property string defaultSshTerm: "xterm-256color"
    readonly property string defaultWaypipeCommand: "waypipe"

    property string terminal: defaultTerminal
    property string sshCommand: defaultSshCommand
    property string sshConfigPath: defaultSshConfigPath
    property string sshTerm: defaultSshTerm
    property string waypipeCommand: defaultWaypipeCommand

    property var sshHosts: []
    property real _lastParse: 0

    property Process _parser: Process {
        command: ["python3", "-I", root._scriptPath(), root.sshConfigPath]
        running: false
        stdout: SplitParser {
            onRead: line => {
                if (!line.trim())
                    return
                try {
                    root.sshHosts = JSON.parse(line)
                    root.pluginService?.requestLauncherUpdate(root.pluginId)
                } catch (e) {
                    console.error(root.pluginId + ": parse error: " + e)
                }
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
        if (query && query.startsWith("@"))
            return _buildUserItems(query.substring(1).trim())
        if (!query)
            _refresh(false)
        return _buildHostItems()
    }

    function getContextMenuActions(item) {
        const actions = [{
            icon: "refresh",
            text: "Reload hosts",
            action: () => root._refresh(true)
        }]
        if (item?.target)
            actions.unshift({
                icon: "content_copy",
                text: "Copy target",
                action: () => Quickshell.execDetached(["dms", "cl", "copy", item.target])
            })
        return actions
    }

    function executeItem(item) {
        switch (item?.kind) {
        case "back":
            _openQuery(trigger + " ")
            break
        case "host":
            _openQuery(trigger + " @" + item.host)
            break
        case "ssh":
            _launchSsh(item.target)
            break
        case "waypipe":
            _launchWaypipe(item)
            break
        }
    }

    function _scriptPath() {
        return (pluginService ? pluginService.getPluginPath(pluginId) : "") + "/parse.py"
    }

    function _loadSettings() {
        if (!pluginService)
            return
        const load = (key, def) => pluginService.loadPluginData(pluginId, key, def) || def
        const oldPath = sshConfigPath
        trigger = pluginService.loadPluginData(pluginId, "trigger", defaultTrigger)
        sshTerm = pluginService.loadPluginData(pluginId, "ssh_term", defaultSshTerm)
        terminal = load("terminal", defaultTerminal)
        sshCommand = load("ssh_command", defaultSshCommand)
        sshConfigPath = load("ssh_config_path", defaultSshConfigPath)
        waypipeCommand = load("waypipe_command", defaultWaypipeCommand)
        _refresh(oldPath !== sshConfigPath || _lastParse === 0)
    }

    function _refresh(force) {
        if (_parser.running || !pluginService)
            return
        if (!force && Date.now() - _lastParse < 5000)
            return
        _lastParse = Date.now()
        _parser.running = true
    }

    function _openQuery(query) {
        Quickshell.execDetached(["dms", "ipc", "call", "spotlight", "openQuery", query])
    }

    function _words(s) {
        return (s || "").split(/\s+/).filter(w => w)
    }

    function _launchSsh(target) {
        const argv = _words(terminal)
        if (!argv.includes("-e"))
            argv.push("-e")
        if (sshTerm)
            argv.push("env", "TERM=" + sshTerm)
        argv.push(..._words(sshCommand), target)
        console.info(pluginId + ": " + argv.join(" "))
        Quickshell.execDetached(argv)
    }

    function _launchWaypipe(item) {
        const argv = [..._words(waypipeCommand), ..._words(item.args), "ssh", item.host, item.app]
        console.info(pluginId + ": " + argv.join(" "))
        Quickshell.execDetached(argv)
    }

    function _usersForHost(host) {
        const users = []
        if (host.user)
            users.push({ name: host.user, isDefault: true })
        for (const u of (host.extraUsers || []))
            if (!users.some(x => x.name === u))
                users.push({ name: u, isDefault: false })
        return users
    }

    function _sshItem(target, comment, icon) {
        return {
            kind: "ssh",
            target: target,
            name: target,
            icon: icon,
            comment: comment,
            action: "ssh:" + target,
            categories: ["SSH"]
        }
    }

    function _buildHostItems() {
        const items = []
        const apps = []
        for (const host of sshHosts) {
            const users = _usersForHost(host)
            if (users.length > 1) {
                items.push({
                    kind: "host",
                    host: host.host,
                    name: host.host,
                    icon: "material:terminal",
                    comment: users.length + " users — press Enter to pick",
                    keywords: users.map(u => u.name),
                    action: "select_host:" + host.host,
                    categories: ["SSH"]
                })
            } else if (users.length === 1) {
                items.push(_sshItem(users[0].name + "@" + host.host, "SSH → " + host.host, "material:terminal"))
            } else {
                items.push(_sshItem(host.host, "SSH connection", "material:terminal"))
            }

            for (const app of (host.waypipe || [])) {
                apps.push({
                    kind: "waypipe",
                    host: host.host,
                    app: app,
                    args: host.waypipeArgs || "",
                    target: host.host,
                    name: app,
                    icon: "material:cast",
                    comment: "Waypipe on " + host.host,
                    keywords: [host.host, "waypipe"],
                    action: "waypipe:" + host.host + ":" + app,
                    categories: ["Waypipe"]
                })
            }
        }
        return items.concat(apps)
    }

    function _buildUserItems(hostname) {
        const backItem = {
            kind: "back",
            name: "← Back to hosts",
            icon: "material:arrow_back",
            comment: "Return to host list",
            action: "back:",
            categories: ["SSH"],
            _preScored: 99999
        }
        const host = sshHosts.find(h => h.host === hostname)
        if (!host)
            return [backItem]
        const userItems = _usersForHost(host).map(u => _sshItem(
            u.name + "@" + hostname,
            "SSH → " + hostname + (u.isDefault ? " (default user)" : ""),
            "material:person"))
        return [backItem, ...userItems]
    }
}
