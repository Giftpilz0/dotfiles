pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int volumeMic: 0

    property list<string> volumeMicIconArray: ["microphone"]
    property int volumeMicIconIndex: 0
    property string volumeMicIcon: "NULL"

    function updateVolumeMicIcon() {
        let normalized = root.volumeMic / 100.0;
        root.volumeMicIconIndex = Math.round(normalized * (root.volumeMicIconArray.length - 1));
        root.volumeMicIcon = volumeMicIconArray[root.volumeMicIconIndex];
    }

    Process {
        id: procVolumeGetMic
        command: ["bash", "-c", "pactl get-source-volume @DEFAULT_SOURCE@ | " + "head -n1 | " + "awk 'NR==1 {gsub(\"%\", \"\", $5); print $5}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: function () {
                root.volumeMic = Number(this.text);
                updateVolumeMicIcon();
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: procVolumeGetMic.running = true
    }

    function updateVolumeMic() {
        procVolumeGetMic.running = true;
    }

    Process {
        id: procVolumeSetMic
        property int setValue: 0
        command: ["pactl", "set-source-volume", "@DEFAULT_SOURCE@", setValue + "%"]
        running: false
        onExited: function () {
            updateVolumeMic();
        }
    }

    function setVolumeMic(volume) {
        let value = Math.round(volume);
        procVolumeSetMic.setValue = value;
        procVolumeSetMic.running = true;
    }

    Component.onCompleted: updateVolumeMic()
}
