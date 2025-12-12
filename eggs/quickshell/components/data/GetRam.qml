pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string ramDisplay: "NULL"

    Process {
        id: ramProcDisplay
        command: ["bash", "-c", "free | awk '/Mem:/ {printf \"%d%%\", $3/$2 * 100}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.ramDisplay = this.text.trim()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: ramProcDisplay.running = true
    }
}
