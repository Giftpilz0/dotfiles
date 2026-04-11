pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string diskDisplay: "NULL"

    Process {
        id: diskProcDisplay
        command: ["bash", "-c", "df -h / | awk 'NR==2 {print $5}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.diskDisplay = this.text.trim()
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: diskProcDisplay.running = true
    }
}
