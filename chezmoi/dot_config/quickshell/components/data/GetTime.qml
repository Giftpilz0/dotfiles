pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string timeDisplay: "NULL"

    Process {
        id: dateProcDisplay
        command: ["date", "+%H:%M Uhr, %A, %d.%m.%Y"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.timeDisplay = this.text
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: dateProcDisplay.running = true
    }
}
