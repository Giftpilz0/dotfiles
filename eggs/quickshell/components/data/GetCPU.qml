pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string cpuDisplay: "NULL"

    Process {
        id: cpuProcDisplay
        command: ["bash", "-c", "vmstat 1 2 | tail -1 | awk '{printf \"%d%%\", 100 - $15}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.cpuDisplay = this.text.trim()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: cpuProcDisplay.running = true
    }
}
