import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

import "../../common"

Rectangle {
    id: bluetoothToggle

    Layout.fillWidth: true
    Layout.preferredHeight: Theme.quickSettingsToggleHeight
    visible: Bluetooth.defaultAdapter !== null

    color: {
        if (bluetoothMouseArea.containsMouse) {
            return (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? Qt.darker(Color.colorPrimary, 1.3) : Qt.darker(Color.colorSurfaceVariant, 1.3);
        }
        return (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? Color.colorPrimary : Color.colorSurface;
    }
    radius: Theme.dashboardQuickSettingsRadius

    Behavior on color {
        ColorAnimation {
            duration: Theme.animationDuration
            easing.type: Theme.easingType
        }
    }

    MouseArea {
        id: bluetoothMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: Bluetooth.defaultAdapter !== null
        onClicked: {
            if (Bluetooth.defaultAdapter) {
                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
            }
        }
    }

    ColumnLayout {
        id: bluetoothContent
        anchors.centerIn: parent
        spacing: Theme.quickSettingsToggleContentSpacing

        Text {
            id: bluetoothIcon
            text: "\uf293" // doesnt work as text...
            font: Theme.quickSettingsToggleIconFont
            color: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? Color.colorOnPrimary : Color.colorOnSurface
            Layout.alignment: Qt.AlignHCenter

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationDuration
                    easing.type: Theme.easingType
                }
            }
        }

        Text {
            id: bluetoothLabel
            text: "Bluetooth"
            font: Theme.quickSettingsToggleLabelFont
            color: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? Color.colorOnPrimary : Color.colorOnSurface
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
