pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int battery: 0
    property bool batteryAvailable: false
    property bool batteryCharging: false

    property list<string> batteryIconArray: ["battery-quarter", "battery-half", "battery-three-quarters", "battery-full"]
    property list<string> batteryChargingIconArray: ["battery-quarter bolt", "battery-half bolt", "battery-three-quarters bolt", "battery-full bolt"]

    property int batteryIconIndex: 0
    property string batteryIcon: "NULL"

    function updateBatteryIcon() {
        let normalized = root.battery / 100.0;
        root.batteryIconIndex = Math.round(normalized * (root.batteryIconArray.length - 1));

        const baseIcons = root.batteryCharging ? root.batteryChargingIconArray : root.batteryIconArray;

        root.batteryIcon = baseIcons[root.batteryIconIndex];
    }

    Process {
        id: procGetBattery
        command: ["bash", "-c", "if ! upower -i /org/freedesktop/UPower/devices/battery_BAT0 >/dev/null 2>&1; then echo NA; exit 0; fi; output=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0); if echo \"$output\" | grep -q 'power supply:[[:space:]]*no'; then echo NA; exit 0; fi; echo \"$output\" | awk '/percentage/ {gsub(\"%\", \"\", $2); p=$2} /state/ {s=$2} END {if (p != \"\" && p > 0) print p, s; else print \"NA\"}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: function () {
                const trimmed = this.text.trim();
                if (trimmed === "NA" || trimmed.length === 0) {
                    root.batteryAvailable = false;
                    return;
                }

                const parts = trimmed.split(/\s+/);
                const percentStr = parts[0];
                const stateStr = parts.length > 1 ? parts[1] : "";

                if (percentStr === "100") {
                    root.batteryAvailable = false;
                    return;
                }

                root.battery = Number(percentStr);
                root.batteryAvailable = true;
                root.batteryCharging = (stateStr === "charging");
                updateBatteryIcon();
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: procGetBattery.running = true
    }
}
