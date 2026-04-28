import Quickshell
import Quickshell.Io
import QtQuick
import qs.Services

QtObject {
    id: root

    // ── Plugin interface ──────────────────────────────────────────────────────
    readonly property string pluginId: "waypipeLauncher"
    property var pluginService: null
    property string trigger: defaultTrigger
    signal itemsChanged()

    // ── Defaults ──────────────────────────────────────────────────────────────
    readonly property string defaultTrigger: "wp"
    readonly property string defaultWaypipeCommand: "waypipe"
    readonly property string defaultConfigPath: "~/.ssh/waypipe.yaml"

    // ── Settings ──────────────────────────────────────────────────────────────
    property string waypipeCommand: defaultWaypipeCommand
    property string configPath: defaultConfigPath

    // ── Runtime state ─────────────────────────────────────────────────────────
    property var entries: []

    // ── Waypipe config parser (uses pyyaml) ───────────────────────────────────
    // Reads ~/.ssh/waypipe.yaml:
    //   hosts:
    //     hostname:
    //       - application: "firefox"
    //         arguments: "--some-flag"
    readonly property var _scriptLines: [
        "import json,os,sys",
        "def p(f):",
        "    r=[]",
        "    try:",
        "        import yaml",
        "        with open(os.path.expanduser(f)) as fp:c=yaml.safe_load(fp)",
        "        for h,es in (c.get('hosts') or {}).items():",
        "            for e in (es or []):r.append({'host':h,'application':e.get('application',''),'arguments':e.get('arguments','')})",
        "    except:pass",
        "    return r",
        "print(json.dumps(p(sys.argv[1])))"
    ]

    // ── Background parser ─────────────────────────────────────────────────────
    property var _parser: Process {
        command: ["python3", "-c", root._scriptLines.join("\n"), root.configPath]
        running: false
        stdout: SplitParser {
            onRead: line => {
                if (!line.trim()) return
                try {
                    root.entries = JSON.parse(line)
                    if (root.pluginService)
                        root.pluginService.requestLauncherUpdate(root.pluginId)
                } catch(e) {
                    console.error(root.pluginId + ": parse error: " + e)
                }
            }
        }
        stderr: SplitParser {
            onRead: line => { if (line.trim()) console.warn(root.pluginId + ": " + line) }
        }
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    Component.onCompleted: {
        if (pluginService) {
            trigger        = pluginService.loadPluginData(pluginId, "trigger",          defaultTrigger)
            waypipeCommand = pluginService.loadPluginData(pluginId, "waypipe_command",  defaultWaypipeCommand)
            configPath     = pluginService.loadPluginData(pluginId, "config_path",      defaultConfigPath)
        }
        _parser.running = true
    }

    // ── Public API ────────────────────────────────────────────────────────────

    function reload() {
        if (pluginService)
            configPath = pluginService.loadPluginData(pluginId, "config_path", defaultConfigPath)
        if (!_parser.running) _parser.running = true
    }

    function getContextMenuActions(item) {
        return [{
            icon: "refresh",
            text: "Reload connections",
            action: () => root.reload()
        }]
    }

    function getItems(query) {
        const items = _buildItems()
        if (!query || query.length === 0) return items

        const q = query.toLowerCase()
        return items.filter(item =>
            item.name.toLowerCase().includes(q) ||
            item.comment.toLowerCase().includes(q)
        )
    }

    function executeItem(item) {
        if (!item?.action) return

        // action format: "waypipe:<host>:<application>:<arguments>"
        const parts       = item.action.substring("waypipe:".length).split(":")
        const host        = parts[0]
        const application = parts[1]
        const argsStr     = parts.slice(2).join(":")
        const wpArgs      = argsStr ? argsStr.trim().split(/\s+/).filter(s => s) : []
        const command     = [waypipeCommand].concat(wpArgs).concat(["ssh", host, application])

        console.info(pluginId + ": " + command.join(" "))
        Quickshell.execDetached(command)
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    function _buildItems() {
        return entries.map(entry => ({
            name: entry.host + " – " + entry.application,
            icon: "material:cast",
            comment: "Waypipe: " + entry.application + " on " + entry.host,
            action: "waypipe:" + entry.host + ":" + entry.application + ":" + (entry.arguments || ""),
            categories: ["Waypipe"]
        }))
    }
}
