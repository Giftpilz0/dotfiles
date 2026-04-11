import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../../common"
import "../bar"

PanelWindow {
    id: powermenu

    visible: ShellState.powermenuVisible
    color: "transparent"

    implicitWidth: Screen.width
    implicitHeight: Screen.height

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    Process {
        id: runner
    }

    function exec(cmd) {
        runner.command = ["sh", "-c", cmd];
        runner.running = true;
        ShellState.powermenuVisible = false;
    }

    property var menuItems: [
        {
            label: "Power off",
            icon: "power-off",
            action: function () {
                exec("systemctl poweroff");
            }
        },
        {
            label: "Reboot",
            icon: "refresh",
            action: function () {
                exec("systemctl reboot");
            }
        },
        {
            label: "Hot Reboot",
            icon: "history",
            action: function () {
                exec("systemctl soft-reboot");
            }
        },
        {
            label: "Lock",
            icon: "lock",
            action: function () {
                exec("loginctl lock-session");
            }
        },
        {
            label: "Suspend",
            icon: "moon",
            action: function () {
                exec("systemctl suspend");
            }
        },
        {
            label: "Sign out",
            icon: "right-from-bracket",
            action: function () {
                exec("loginctl terminate-user $USER");
            }
        }
    ]

    Rectangle {
        anchors.fill: parent
        color: Theme.powermenuBackgroundOverlayColor
        TapHandler {
            onTapped: ShellState.powermenuVisible = false
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent

        width: grid.implicitWidth + Theme.powermenuCardPadding
        height: grid.implicitHeight + Theme.powermenuCardPadding

        radius: Theme.barRadius
        color: Color.colorBackground

        property bool hasEntered: false
        HoverHandler {
            id: mouseWatcher
            onHoveredChanged: {
                if (hovered) {
                    card.hasEntered = true;
                }
            }
        }

        Timer {
            interval: Theme.powermenuAutoCloseDelay
            running: ShellState.powermenuVisible && card.hasEntered && !mouseWatcher.hovered
            onTriggered: {
                card.hasEntered = false;
                ShellState.powermenuVisible = false;
            }
        }

        GridLayout {
            id: grid
            anchors.centerIn: parent
            columns: Theme.powermenuGridColumns
            columnSpacing: Theme.powermenuGridColumnSpacing
            rowSpacing: Theme.powermenuGridRowSpacing

            Repeater {
                model: powermenu.menuItems

                delegate: BarWidget {
                    id: buttonDelegate

                    Layout.preferredWidth: Theme.powermenuButtonWidth
                    Layout.preferredHeight: Theme.powermenuButtonHeight

                    isButton: true
                    onClick: modelData.action

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.powermenuButtonRadius
                        color: buttonDelegate.hovered ? Theme.powermenuButtonHoverColor : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.powermenuHoverAnimationDuration
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.powermenuButtonContentSpacing

                        Text {
                            text: modelData.icon
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: Color.colorOnBackground
                            font: Theme.powermenuIconFont
                        }

                        Text {
                            text: modelData.label
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: Color.colorOnBackground
                            font: Theme.barFont
                        }
                    }
                }
            }
        }
    }
}
