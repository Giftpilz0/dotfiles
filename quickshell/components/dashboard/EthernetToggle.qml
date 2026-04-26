import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import "../../common"

Rectangle {
    id: ethernetToggle

    property bool connected: false
    property string connectionName: ""

    Layout.fillWidth: true
    Layout.preferredHeight: Theme.quickSettingsToggleHeight
    visible: ethernetToggle.connectionName !== ""

    color: {
        if (ethernetMouseArea.containsMouse) {
            return ethernetToggle.connected ? Qt.darker(Color.colorPrimary, 1.3) : Qt.darker(Color.colorSurfaceVariant, 1.3);
        }
        return ethernetToggle.connected ? Color.colorPrimary : Color.colorSurface;
    }
    radius: Theme.dashboardQuickSettingsRadius

    Behavior on color {
        ColorAnimation {
            duration: Theme.animationDuration
            easing.type: Theme.easingType
        }
    }

    Process {
        id: ethernetToggleProcess
        property bool enable: false
        command: ["/bin/bash", "-c", enable ? "nmcli connection up '" + ethernetToggle.connectionName + "'" : "nmcli connection down '" + ethernetToggle.connectionName + "'"]
    }

    Timer {
        id: ethernetPollingTimer
        interval: Theme.quickSettingsTogglePollingInterval
        running: true
        repeat: true
        onTriggered: {
            ethernetStatusProcess.running = true;
            ethernetNameProcess.running = true;
        }
        Component.onCompleted: triggered()
    }

    Process {
        id: ethernetStatusProcess
        command: ["/bin/bash", "-c", "nmcli -t -f TYPE,STATE device status | grep -c '^ethernet:connected'"]
        stdout: SplitParser {
            onRead: data => {
                ethernetToggle.connected = parseInt(data.trim()) > 0;
            }
        }
    }

    Process {
        id: ethernetNameProcess
        command: ["/bin/bash", "-c", "nmcli -t -f NAME,TYPE connection show | grep ':802-3-ethernet$' | head -1 | cut -d: -f1"]
        stdout: SplitParser {
            onRead: data => {
                ethernetToggle.connectionName = data.trim();
            }
        }
    }

    MouseArea {
        id: ethernetMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: ethernetToggle.connectionName !== ""
        onClicked: {
            if (ethernetToggle.connectionName) {
                ethernetToggleProcess.enable = !ethernetToggle.connected;
                ethernetToggleProcess.running = true;
            }
        }
    }

    ColumnLayout {
        id: ethernetContent
        anchors.centerIn: parent
        spacing: Theme.quickSettingsToggleContentSpacing

        Text {
            id: ethernetIcon
            text: "network-wired"
            font: Theme.quickSettingsToggleIconFont
            color: ethernetToggle.connected ? Color.colorOnPrimary : Color.colorOnSurface
            Layout.alignment: Qt.AlignHCenter

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationDuration
                    easing.type: Theme.easingType
                }
            }
        }

        Text {
            id: ethernetLabel
            text: "Ethernet"
            font: Theme.quickSettingsToggleLabelFont
            color: ethernetToggle.connected ? Color.colorOnPrimary : Color.colorOnSurface
            Layout.alignment: Qt.AlignHCenter

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationDuration
                    easing.type: Theme.easingType
                }
            }
        }
    }
}
