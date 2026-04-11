pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int volumeSpeaker: 0

    property list<string> volumeSpeakerIconArray: ["volume-low", "volume-high"]
    property int volumeSpeakerIconIndex: 0
    property string volumeSpeakerIcon: "NULL"

    function updateVolumeSpeakerIcon() {
        let normalized = root.volumeSpeaker / 100.0;
        root.volumeSpeakerIconIndex = Math.round(normalized * (root.volumeSpeakerIconArray.length - 1));
        root.volumeSpeakerIcon = root.volumeSpeakerIconArray[root.volumeSpeakerIconIndex];
    }

    Process {
        id: procVolumeGetSpeaker
        command: ["bash", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | " + "head -n1 | " + "awk 'NR==1 {gsub(\"%\", \"\", $5); print $5}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: function () {
                root.volumeSpeaker = Number(this.text);
                updateVolumeSpeakerIcon();
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: procVolumeGetSpeaker.running = true
    }

    function updateVolumeSpeaker() {
        procVolumeGetSpeaker.running = true;
    }

    Process {
        id: procVolumeSetSpeaker
        property int setValue: 0
        command: ["pactl", "set-sink-volume", "@DEFAULT_SINK@", setValue + "%"]
        running: false
        onExited: function () {
            updateVolumeSpeaker();
        }
    }

    function setVolumeSpeaker(volume) {
        let value = Math.round(volume);
        procVolumeSetSpeaker.setValue = value;
        procVolumeSetSpeaker.running = true;
    }

    Component.onCompleted: updateVolumeSpeaker()
}
