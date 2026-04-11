import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../common"

PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight

    color: "transparent"

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: Theme.barLeftRightGap
        anchors.rightMargin: Theme.barLeftRightGap
        anchors.topMargin: Theme.barTopGap
        anchors.bottomMargin: Theme.barBottomGap

        radius: Theme.barRadius

        color: Color.colorBackground

        RowLayout {
            id: barSegments

            anchors.fill: parent
            anchors.leftMargin: Theme.barSideMargin
            anchors.rightMargin: Theme.barSideMargin

            BarLeft {}
            BarMiddle {}
            BarRight {}
        }
    }
}
