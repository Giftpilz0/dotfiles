import QtQuick
import Quickshell
import Quickshell.Wayland

import "../../common"

PanelWindow {
    id: wallpaper

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background

    color: "black"

    Image {
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: Qt.resolvedUrl("../../wallpapers/" + Theme.wallpaper)
    }
}
