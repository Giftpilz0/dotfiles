import QtQuick
import QtQuick.Layouts

import "../../common"

Item {
    id: barRight

    Layout.fillWidth: true
    Layout.fillHeight: true

    RowLayout {
        id: barRightLayout

        anchors.right: barRight.right
        anchors.verticalCenter: barRight.verticalCenter

        BarWidget {
            id: notificationWidget

            isButton: true
            onClick: function () {
                if (ShellState.notificationCenterVisible) {
                    ShellState.notificationCenterVisible = false;
                } else {
                    ShellState.notificationCenterVisible = true;
                }
            }

            Text {
                text: "bell"
                anchors.centerIn: parent
                color: Color.colorOnBackground
                font: Theme.barIconFont
            }
        }

        BarWidget {
            id: dashboardWidget

            isButton: true
            onClick: function () {
                if (ShellState.dashboardVisible) {
                    ShellState.dashboardVisible = false;
                } else {
                    ShellState.dashboardVisible = true;
                }
            }
            Text {
                text: "gear"
                anchors.centerIn: parent
                color: Color.colorOnBackground
                font: Theme.barIconFont
            }
        }

        BarWidget {
            id: powerWidget

            isButton: true
            onClick: function () {
                if (ShellState.powermenuVisible) {
                    ShellState.powermenuVisible = false;
                } else {
                    ShellState.powermenuVisible = true;
                }
            }
            Text {
                text: "power-off"
                anchors.centerIn: parent
                color: Color.colorOnBackground
                font: Theme.barIconFont
            }
        }
    }
}
