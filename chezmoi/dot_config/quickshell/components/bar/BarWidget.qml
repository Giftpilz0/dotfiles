import QtQuick

import "../../common"

Rectangle {
    id: root

    default property alias contents: items.data

    property bool indicateActive: false
    property string indicateActiveColor: Color.colorPrimaryContainer

    property bool isButton: false
    property var onClick: function () {
        console.log("BarWidget clicked, but no behavior defined.");
    }

    implicitWidth: items.childrenRect.width + Theme.barWidgetHorizontalPadding
    implicitHeight: items.childrenRect.height + Theme.barWidgetVerticalPadding

    radius: Theme.barWidgetRadius
    color: indicateActive ? indicateActiveColor : ((mouse_area.containsMouse && isButton) ? Color.colorSurfaceVariant : Color.colorSurface)

    Item {
        id: items
        anchors.fill: parent
    }

    MouseArea {
        id: mouse_area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: isButton ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: function () {
            if (isButton) {
                onClick();
            }
        }
    }
}
