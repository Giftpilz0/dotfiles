import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../../common"

Rectangle {
    id: wallpaperToggle

    Layout.fillWidth: true
    Layout.preferredHeight: Theme.quickSettingsToggleHeight

    color: wallpaperMouseArea.containsMouse ? Qt.darker(Color.colorSurfaceVariant, 1.3) : Color.colorSurface
    radius: Theme.dashboardQuickSettingsRadius

    Behavior on color {
        ColorAnimation {
            duration: Theme.animationDuration
            easing.type: Theme.easingType
        }
    }

    property var wallpapers: []
    property int currentIndex: 0
    property string themePath: Quickshell.env("HOME") + "/.config/quickshell/common/Theme.qml"
    property string wallpapersDir: Quickshell.env("HOME") + "/.config/quickshell/wallpapers/"

    Timer {
        id: rescanTimer
        interval: 10000
        running: true
        repeat: true
        onTriggered: wallpaperToggle.scanWallpapers()
    }

    Process {
        id: scanProcess
        running: false

        stdout: SplitParser {
            onRead: data => {
                if (data.length > 0) {
                    wallpaperToggle.wallpapers.push(data);
                }
            }
        }

        onExited: {
            if (wallpaperToggle.wallpapers.length > 0) {
                var idx = 0;
                for (var i = 0; i < wallpaperToggle.wallpapers.length; i++) {
                    if (wallpaperToggle.wallpapers[i] === Theme.wallpaper) {
                        idx = i;
                        break;
                    }
                }
                wallpaperToggle.currentIndex = idx;
            }
        }
    }

    Process {
        id: changeProcess
        running: false
    }

    Component.onCompleted: scanWallpapers()

    function scanWallpapers() {
        wallpapers = [];

        var cmd = "cd '" + wallpapersDir + "' 2>/dev/null && " + "ls *.png *.jpg *.jpeg *.webp 2>/dev/null | sort";

        scanProcess.command = ["bash", "-c", cmd];
        scanProcess.running = true;
    }

    function cycleWallpaper() {
        if (wallpapers.length === 0)
            return;

        currentIndex = (currentIndex + 1) % wallpapers.length;
        var newWallpaper = wallpapers[currentIndex];
        var fullPath = wallpapersDir + newWallpaper;

        var cmd = "sed -i 's|property string wallpaper: \".*\"|property string wallpaper: \"" + newWallpaper + "\"|' '" + themePath + "' && " + "matugen image '" + fullPath + "' --mode dark --type scheme-content --source-color-index 0 2>&1";

        changeProcess.command = ["bash", "-c", cmd];
        changeProcess.running = true;

        Theme.wallpaper = newWallpaper;
    }

    MouseArea {
        id: wallpaperMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: wallpaperToggle.cycleWallpaper()
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.quickSettingsToggleContentSpacing

        Rectangle {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignHCenter
            color: Color.colorBackground
            border.color: Color.colorOutline
            border.width: 1

            Image {
                anchors.fill: parent
                anchors.margins: 1
                source: Qt.resolvedUrl("../../wallpapers/" + Theme.wallpaper)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
            }
        }

        Text {
            text: "Wallpaper"
            font: Theme.quickSettingsToggleLabelFont
            color: Color.colorOnSurface
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
