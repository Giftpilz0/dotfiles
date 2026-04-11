import QtQuick
import QtQuick.Layouts

import "../../common"
import "../data"

Item {
    id: barMiddle

    Layout.fillWidth: true
    Layout.fillHeight: true

    RowLayout {
        id: barMiddleLayout

        anchors.horizontalCenter: barMiddle.horizontalCenter
        anchors.verticalCenter: barMiddle.verticalCenter

        BarWidget {
            id: dateWidget

            Text {
                text: GetTime.timeDisplay
                anchors.centerIn: parent
                color: Color.colorOnBackground
                font: Theme.barFont
            }
        }
    }
}
