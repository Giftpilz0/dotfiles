import QtQuick
import QtQuick.Layouts

import "../../common"
import "../data"

Item {
    id: barLeft

    Layout.fillWidth: true
    Layout.fillHeight: true

    RowLayout {
        id: barLeftLayout

        anchors.left: barLeft.left
        anchors.verticalCenter: barLeft.verticalCenter

        BarWidget {
            id: diskWidget

            implicitWidth: rowDisk.implicitWidth + Theme.barWidgetContentHorizontalPadding * 2
            implicitHeight: rowDisk.implicitHeight + Theme.barWidgetVerticalPadding

            Row {
                id: rowDisk
                anchors.fill: parent
                anchors.leftMargin: Theme.barWidgetContentHorizontalPadding
                anchors.rightMargin: Theme.barWidgetContentHorizontalPadding
                spacing: Theme.barWidgetContentSpacing

                Text {
                    text: "hard-drive"
                    anchors.verticalCenter: parent.verticalCenter
                    color: Color.colorOnBackground
                    font: Theme.barIconFont
                }

                Text {
                    text: GetDisk.diskDisplay
                    anchors.verticalCenter: parent.verticalCenter
                    color: Color.colorOnBackground
                    font: Theme.barFont
                }
            }
        }

        BarWidget {
            id: ramWidget

            implicitWidth: rowRam.implicitWidth + Theme.barWidgetContentHorizontalPadding * 2
            implicitHeight: rowRam.implicitHeight + Theme.barWidgetVerticalPadding

            Row {
                id: rowRam
                anchors.fill: parent
                anchors.leftMargin: Theme.barWidgetContentHorizontalPadding
                anchors.rightMargin: Theme.barWidgetContentHorizontalPadding
                spacing: Theme.barWidgetContentSpacing

                Text {
                    text: "memory"
                    anchors.verticalCenter: parent.verticalCenter
                    color: Color.colorOnBackground
                    font: Theme.barIconFont
                }

                Text {
                    text: GetRam.ramDisplay
                    anchors.verticalCenter: parent.verticalCenter
                    color: Color.colorOnBackground
                    font: Theme.barFont
                }
            }
        }

        BarWidget {
            id: cpuWidget

            implicitWidth: rowCpu.implicitWidth + Theme.barWidgetContentHorizontalPadding * 2
            implicitHeight: rowCpu.implicitHeight + Theme.barWidgetVerticalPadding

            Row {
                id: rowCpu
                anchors.fill: parent
                anchors.leftMargin: Theme.barWidgetContentHorizontalPadding
                anchors.rightMargin: Theme.barWidgetContentHorizontalPadding
                spacing: Theme.barWidgetContentSpacing

                Text {
                    text: "microchip"
                    anchors.verticalCenter: parent.verticalCenter
                    color: Color.colorOnBackground
                    font: Theme.barIconFont
                }

                Text {
                    text: GetCPU.cpuDisplay
                    anchors.verticalCenter: parent.verticalCenter
                    color: Color.colorOnBackground
                    font: Theme.barFont
                }
            }
        }

        BarWidget {
            id: batteryWidget

            visible: GetBattery.batteryAvailable

            implicitWidth: rowBattery.implicitWidth + Theme.barWidgetContentHorizontalPadding * 2
            implicitHeight: rowBattery.implicitHeight + Theme.barWidgetVerticalPadding

            Row {
                id: rowBattery
                anchors.fill: parent
                anchors.leftMargin: Theme.barWidgetContentHorizontalPadding
                anchors.rightMargin: Theme.barWidgetContentHorizontalPadding
                spacing: Theme.barWidgetContentSpacing

                Text {
                    text: GetBattery.batteryIcon
                    anchors.verticalCenter: parent.verticalCenter
                    color: Color.colorOnBackground
                    font: Theme.barIconFont
                }

                Text {
                    text: GetBattery.battery + "%"
                    anchors.verticalCenter: parent.verticalCenter
                    color: Color.colorOnBackground
                    font: Theme.barFont
                }
            }
        }
    }
}
