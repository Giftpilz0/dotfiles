pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int brightness: 0
    property bool hasDimmableDisplay: false

    property list<string> brightnessIconArray: ["sun"]
    property int brightnessIconIndex: 0
    property string brightnessIcon: "NULL"

    function updateBrightnessIcon() {
        let normalized = root.brightness / 100.0;
        root.brightnessIconIndex = Math.round(normalized * (root.brightnessIconArray.length - 1));
        root.brightnessIcon = root.brightnessIconArray[root.brightnessIconIndex];
    }

    Process {
        id: procBrightnessGet
        command: ["bash", "-c", "[ -n \"$(ls -A /sys/class/backlight 2>/dev/null)\" ] || " + "{ echo 'NOBACKLIGHT'; exit 0; }; " + "dev=$(brightnessctl --class=backlight -m --list 2>/dev/null | " + " head -n1 | cut -d',' -f1); " + "[ -z \"$dev\" ] && { echo 'NOBACKLIGHT'; exit 0; }; " + "vget=$(brightnessctl --device=\"$dev\" get); " + "vmax=$(brightnessctl --device=\"$dev\" max); " + "echo $((vget * 100 / vmax))"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: function () {
                if (text.trim() === "NOBACKLIGHT") {
                    root.hasDimmableDisplay = false;
                    return;
                }

                root.hasDimmableDisplay = true;
                root.brightness = Number(this.text);
                updateBrightnessIcon();
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: procBrightnessGet.running = true
    }

    function updateBrightness() {
        procBrightnessGet.running = true;
    }

    Process {
        id: procBrightnessSet
        property int setValue: 0
        command: ["brightnessctl", "set", setValue + "%"]
        running: false
        onExited: function () {
            updateBrightness();
        }
    }

    function setBrightness(brightness) {
        let value = Math.round(brightness);
        procBrightnessSet.setValue = value;
        procBrightnessSet.running = true;
    }

    Component.onCompleted: updateBrightness()
}
