import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

import "../../common"

PopupWindow {
    id: notificationCenter

    property PanelWindow anchorWindow
    property var notificationServer: null

    visible: ShellState.notificationCenterVisible
    color: "transparent"

    implicitWidth: Theme.dashboardWidth
    implicitHeight: Math.max(Theme.dashboardHeight, notificationContent.implicitHeight + (Theme.dashboardContentPadding * 2) + (Theme.dashboardMargin * 2))

    property bool hasEntered: false

    HoverHandler {
        id: notificationHoverHandler

        onHoveredChanged: {
            if (hovered) {
                notificationCenter.hasEntered = true;
            }
        }
    }

    Timer {
        id: autoCloseTimer

        interval: Theme.dashboardAutoCloseDelay
        running: ShellState.notificationCenterVisible && notificationCenter.hasEntered && !notificationHoverHandler.hovered

        onTriggered: {
            notificationCenter.hasEntered = false;
            ShellState.notificationCenterVisible = false;
        }
    }

    anchor.window: anchorWindow
    anchor.rect.x: anchorWindow.width - width
    anchor.rect.y: anchorWindow.height

    Rectangle {
        id: notificationBackground

        anchors.fill: parent
        color: Color.colorBackground
        radius: Theme.barRadius

        anchors.leftMargin: Theme.dashboardMargin
        anchors.rightMargin: 0
        anchors.topMargin: Theme.dashboardMargin
        anchors.bottomMargin: Theme.dashboardMargin

        ColumnLayout {
            id: notificationContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.dashboardContentPadding

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.dashboardSlidersSpacing
                spacing: Theme.notificationsHeaderSpacing

                Text {
                    text: "Notifications"
                    font: Theme.notificationHeaderFont
                    color: Color.colorOnBackground
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                id: notificationsContainer

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Theme.dashboardNotificationsTopMargin
                Layout.preferredHeight: notificationsLayout.implicitHeight + (Theme.dashboardNotificationsMargin * 2)

                color: Color.colorSurface
                radius: Theme.dashboardNotificationsRadius

                ColumnLayout {
                    id: notificationsLayout

                    anchors.fill: parent
                    anchors.margins: Theme.dashboardNotificationsMargin
                    spacing: Theme.dashboardNotificationsSpacing

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ListView {
                            id: notificationList

                            model: notificationCenter.notificationServer ? notificationCenter.notificationServer.trackedNotifications : []
                            spacing: Theme.notificationListSpacing

                            delegate: Rectangle {
                                width: notificationList.width
                                height: notificationLayout.implicitHeight + (Theme.notificationCardMargin * 2)

                                color: Color.colorSurfaceVariant
                                radius: Theme.notificationCardRadius

                                ColumnLayout {
                                    id: notificationLayout

                                    anchors.fill: parent
                                    anchors.margins: Theme.notificationCardMargin
                                    spacing: Theme.notificationCardSpacing

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: modelData.appName || ""
                                            font: Theme.notificationHeaderFont
                                            color: Color.colorOnBackground
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "xmark"
                                            font: Theme.notificationCloseFont
                                            color: Color.colorOnBackground

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: modelData.dismiss()
                                            }
                                        }
                                    }

                                    Text {
                                        text: modelData.summary || ""
                                        font: Theme.notificationSummaryFont
                                        color: Color.colorOnBackground
                                        wrapMode: Text.Wrap
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                    }

                                    Text {
                                        text: modelData.body || ""
                                        font: Theme.notificationBodyFont
                                        color: Color.colorOnBackground
                                        wrapMode: Text.Wrap
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.dashboardNotificationsSpacing
                                        visible: modelData.actions && modelData.actions.length > 0

                                        Repeater {
                                            model: modelData.actions

                                            Rectangle {
                                                Layout.preferredHeight: Theme.notificationActionHeight
                                                Layout.preferredWidth: actionText.implicitWidth + Theme.notificationActionPadding

                                                color: Color.colorPrimary
                                                radius: Theme.notificationActionRadius

                                                Text {
                                                    id: actionText

                                                    text: modelData.text || ""
                                                    font: Theme.notificationActionFont
                                                    color: Color.colorOnPrimary
                                                    anchors.centerIn: parent
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: modelData.invoke()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "No notifications"
                        font: Theme.notificationEmptyFont
                        color: Color.colorOnBackground
                        opacity: Theme.notificationEmptyOpacity
                        visible: notificationList.count === 0
                        Layout.alignment: Qt.AlignCenter
                    }
                }
            }
        }
    }
}
