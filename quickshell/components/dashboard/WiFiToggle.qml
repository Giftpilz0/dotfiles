import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import "../../common"

Rectangle {
    id: wifiToggle

    property bool wifiEnabled: false
    property bool wifiAvailable: false

    Layout.fillWidth: true
    Layout.preferredHeight: Theme.quickSettingsToggleHeight
    visible: wifiToggle.wifiAvailable

    color: {
        if (wifiMouseArea.containsMouse) {
            return wifiToggle.wifiEnabled ? Qt.darker(Color.colorPrimary, 1.3) : Qt.darker(Color.colorSurfaceVariant, 1.3);
        }
        return wifiToggle.wifiEnabled ? Color.colorPrimary : Color.colorSurface;
    }
    radius: Theme.dashboardQuickSettingsRadius

    Behavior on color {
        ColorAnimation {
            duration: Theme.animationDuration
            easing.type: Theme.easingType
        }
    }

    Process {
        id: wifiToggleProcess
        property bool enable: false
        command: ["/bin/bash", "-c", "nmcli radio wifi " + (enable ? "on" : "off")]
    }

    Timer {
        id: wifiPollingTimer
        interval: Theme.quickSettingsTogglePollingInterval
        running: true
        repeat: true
        onTriggered: {
            wifiStatusProcess.running = true;
            wifiAvailabilityProcess.running = true;
        }
        Component.onCompleted: triggered()
    }

    Process {
        id: wifiStatusProcess
        command: ["/bin/bash", "-c", "nmcli radio wifi"]
        stdout: SplitParser {
            onRead: data => {
                wifiToggle.wifiEnabled = data.trim() === "enabled";
            }
        }
    }

    Process {
        id: wifiAvailabilityProcess
        command: ["/bin/bash", "-c", "nmcli -t -f TYPE device status | grep -c '^wifi$'"]
        stdout: SplitParser {
            onRead: data => {
                wifiToggle.wifiAvailable = parseInt(data.trim()) > 0;
            }
        }
    }

    MouseArea {
        id: wifiMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            wifiToggleProcess.enable = !wifiToggle.wifiEnabled;
            wifiToggleProcess.running = true;
        }
    }

    ColumnLayout {
        id: wifiContent
        anchors.centerIn: parent
        spacing: Theme.quickSettingsToggleContentSpacing

        Text {
            id: wifiIcon
            text: "wifi"
            font: Theme.quickSettingsToggleIconFont
            color: wifiToggle.wifiEnabled ? Color.colorOnPrimary : Color.colorOnSurface
            Layout.alignment: Qt.AlignHCenter

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationDuration
                    easing.type: Theme.easingType
                }
            }
        }

        Text {
            id: wifiLabel
            text: "WiFi"
            font: Theme.quickSettingsToggleLabelFont
            color: wifiToggle.wifiEnabled ? Color.colorOnPrimary : Color.colorOnSurface
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
