import Quickshell
import Quickshell.Io
import QtQuick
import qs.Services

QtObject {
    id: root

    // ── Plugin interface ──────────────────────────────────────────────────────
    readonly property string pluginId: "sshLauncher"
    property var pluginService: null
    property string trigger: defaultTrigger
    signal itemsChanged()

    // ── Defaults ──────────────────────────────────────────────────────────────
    readonly property string defaultTrigger: "ssh"
    readonly property string defaultTerminal: Quickshell.env("TERMINAL") || "kitty"
    readonly property string defaultSshCommand: "ssh"
    readonly property string defaultSshConfigPath: "~/.ssh/config"
    readonly property string defaultSshTerm: "xterm-256color"

    // ── Settings ──────────────────────────────────────────────────────────────
    property string terminal: defaultTerminal
    property string sshCommand: defaultSshCommand
    property string sshConfigPath: defaultSshConfigPath
    property string sshTerm: defaultSshTerm

    // ── Runtime state ─────────────────────────────────────────────────────────
    property var sshHosts: []

    // ── SSH config parser (pure stdlib Python) ────────────────────────────────
    // Handles Include directives, User entries and
    // "# fuzzel-users: user1,user2" comments for extra users per host.
    readonly property var _scriptLines: [
        "import json,os,glob,sys",
        "def p(f,s=None):",
        "    if s is None:s=set()",
        "    if f in s:return []",
        "    s.add(f);r=[];ch=cn=None;ce=[]",
        "    def flush():",
        "        if not ch:return",
        "        for h in ch.split():",
        "            if not any(c in h for c in '*?'):r.append({'host':h,'user':cn,'extraUsers':ce})",
        "    try:",
        "        for l in open(os.path.expanduser(f)):",
        "            l=l.strip()",
        "            if l.startswith('#'):",
        "                if 'fuzzel-users:' in l:ce=[u.strip() for u in l.split('fuzzel-users:',1)[1].split(',') if u.strip()]",
        "                continue",
        "            if l.startswith('Include '):",
        "                for pat in l.split()[1:]:",
        "                    if not os.path.isabs(pat):pat=os.path.join(os.path.dirname(os.path.expanduser(f)),pat)",
        "                    for m in sorted(glob.glob(os.path.expanduser(pat))):r.extend(p(m,s))",
        "            elif l.upper().startswith('HOST '):",
        "                flush();pts=l.split(None,1);ch=pts[1] if len(pts)>1 else None;cn=None;ce=[]",
        "            elif l.upper().startswith('USER ') and ch:",
        "                pts=l.split(None,1)",
        "                if len(pts)>1:cn=pts[1]",
        "    except:pass",
        "    flush()",
        "    return r",
        "print(json.dumps(p(sys.argv[1])))"
    ]

    // ── Background parser ─────────────────────────────────────────────────────
    property var _parser: Process {
        command: ["python3", "-c", root._scriptLines.join("\n"), root.sshConfigPath]
        running: false
        stdout: SplitParser {
            onRead: line => {
                if (!line.trim()) return
                try {
                    root.sshHosts = JSON.parse(line)
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
            trigger       = pluginService.loadPluginData(pluginId, "trigger",         defaultTrigger)
            terminal      = pluginService.loadPluginData(pluginId, "terminal",        defaultTerminal)
            sshCommand    = pluginService.loadPluginData(pluginId, "ssh_command",     defaultSshCommand)
            sshConfigPath = pluginService.loadPluginData(pluginId, "ssh_config_path", defaultSshConfigPath)
            sshTerm       = pluginService.loadPluginData(pluginId, "ssh_term",        defaultSshTerm)
        }
        _parser.running = true
    }

    // ── Public API ────────────────────────────────────────────────────────────

    function reload() {
        if (pluginService)
            sshConfigPath = pluginService.loadPluginData(pluginId, "ssh_config_path", defaultSshConfigPath)
        if (!_parser.running) _parser.running = true
    }

    function getContextMenuActions(item) {
        return [{
            icon: "refresh",
            text: "Reload connections",
            action: () => root.reload()
        }]
    }

    // query starts with "@hostname" → user picker for that host
    // otherwise → host list
    function getItems(query) {
        if (query && query.startsWith("@")) {
            const hostname = query.substring(1).replace(/\s+$/, "")
            return _buildUserItems(hostname)
        }
        return _buildHostItems(query)
    }

    function executeItem(item) {
        if (!item?.action) return

        if (item.action === "back:") {
            Quickshell.execDetached(["dms", "ipc", "call", "spotlight", "openQuery", trigger + " "])
            return
        }

        if (item.action.startsWith("select_host:")) {
            const hostname = item.action.substring("select_host:".length)
            Quickshell.execDetached(["dms", "ipc", "call", "spotlight", "openQuery", trigger + " @" + hostname])
            return
        }

        // action = "ssh:<target>"
        const target = item.action.substring("ssh:".length)
        const termcmd = (" " + terminal + " ").includes(" -e ")
            ? terminal
            : terminal + " -e"
        const envPrefix = sshTerm ? "env TERM=" + sshTerm + " " : ""
        const command = termcmd.split(" ").filter(s => s).concat(
            "sh", "-c", envPrefix + sshCommand + " " + target
        )
        console.info(pluginId + ": " + command.join(" "))
        Quickshell.execDetached(command)
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    function _usersForHost(host) {
        const users = []
        if (host.user) users.push({ name: host.user, isDefault: true })
        for (const u of (host.extraUsers || [])) {
            if (!users.some(x => x.name === u))
                users.push({ name: u, isDefault: false })
        }
        return users
    }

    function _buildHostItems(query) {
        const q = query ? query.toLowerCase() : ""
        const items = []
        for (let i = 0; i < sshHosts.length; i++) {
            const host = sshHosts[i]
            const users = _usersForHost(host)

            let item
            if (users.length <= 1) {
                const target = users.length === 1
                    ? users[0].name + "@" + host.host
                    : host.host
                item = {
                    name: target,
                    icon: "material:terminal",
                    comment: users.length === 1 ? "SSH → " + host.host : "SSH connection",
                    action: "ssh:" + target,
                    categories: ["SSH"]
                }
            } else {
                item = {
                    name: host.host,
                    icon: "material:terminal",
                    comment: users.length + " users — press Enter to pick",
                    action: "select_host:" + host.host,
                    categories: ["SSH"]
                }
            }

            if (!q || item.name.toLowerCase().includes(q) || item.comment.toLowerCase().includes(q))
                items.push(item)
        }
        return items
    }

    function _buildUserItems(hostname) {
        const backItem = {
            name: "← Back to hosts",
            icon: "material:arrow_back",
            comment: "Return to host list",
            action: "back:",
            categories: ["SSH"],
            _preScored: 99999
        }

        const host = sshHosts.find(h => h.host === hostname) || null
        if (!host) return [backItem]

        const userItems = _usersForHost(host).map(u => ({
            name: u.name + "@" + hostname,
            icon: "material:person",
            comment: "SSH → " + hostname + (u.isDefault ? " (default user)" : ""),
            action: "ssh:" + u.name + "@" + hostname,
            categories: ["SSH"]
        }))

        return [backItem, ...userItems]
    }
}
