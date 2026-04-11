import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import QtQuick.Effects

import "../common"

Item {
    id: root
    required property LockContext context

    anchors.fill: parent

    // Wallpaper
    Image {
        id: wallpaperSource
        anchors.fill: parent
        source: Qt.resolvedUrl("../wallpapers/" + Theme.wallpaper)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // Blur effect
    MultiEffect {
        id: blurEffect
        anchors.fill: parent
        anchors.margins: -64
        source: wallpaperSource

        blurEnabled: true
        blurMax: 64
        blur: Theme.lockscreenBlurAmount

        brightness: Theme.lockscreenBrightness
    }

    // Main content
    Item {
        anchors.fill: parent

        // Clock
        ColumnLayout {
            id: clockSection
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: Theme.lockscreenClockTopMargin
            }
            spacing: 8

            Label {
                id: clock
                property var date: new Date()

                Layout.alignment: Qt.AlignHCenter

                renderType: Text.NativeRendering
                font: Theme.lockscreenClockFont
                color: Color.colorOnBackground

                Timer {
                    running: true
                    repeat: true
                    interval: 1000
                    onTriggered: clock.date = new Date()
                }

                text: {
                    const hours = date.getHours().toString().padStart(2, '0');
                    const minutes = date.getMinutes().toString().padStart(2, '0');
                    return `${hours}:${minutes}`;
                }
            }

            Label {
                id: dateLabel
                property var date: clock.date

                Layout.alignment: Qt.AlignHCenter

                renderType: Text.NativeRendering
                font: Theme.lockscreenDateFont
                color: Color.colorOnSurfaceVariant

                text: {
                    const options = {
                        weekday: 'long',
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric'
                    };
                    return date.toLocaleDateString(undefined, options);
                }
            }
        }

        // Password entry
        ColumnLayout {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: clockSection.bottom
                topMargin: Theme.lockscreenInputTopMargin
            }
            spacing: Theme.lockscreenButtonSpacing

            RowLayout {
                spacing: Theme.lockscreenButtonSpacing
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    id: passwordContainer
                    Layout.preferredWidth: Theme.lockscreenInputWidth
                    Layout.preferredHeight: Theme.lockscreenInputHeight
                    color: Color.colorSurface
                    radius: Theme.lockscreenInputRadius

                    TextField {
                        id: passwordBox
                        anchors.fill: parent
                        anchors.margins: 16

                        focus: true
                        enabled: !root.context.unlockInProgress
                        echoMode: TextInput.Password
                        inputMethodHints: Qt.ImhSensitiveData

                        color: Color.colorOnSurface
                        font: Theme.lockscreenInputFont

                        background: Rectangle {
                            color: "transparent"
                        }

                        placeholderText: "Enter password"
                        placeholderTextColor: Color.colorOnSurfaceVariant

                        onTextChanged: root.context.currentText = text
                        onAccepted: root.context.tryUnlock()

                        Connections {
                            target: root.context
                            function onCurrentTextChanged() {
                                passwordBox.text = root.context.currentText;
                            }
                        }
                    }
                }

                Rectangle {
                    id: unlockButton
                    Layout.preferredWidth: Theme.lockscreenButtonWidth
                    Layout.preferredHeight: Theme.lockscreenButtonHeight
                    color: enabled ? Color.colorPrimary : Color.colorSurfaceVariant
                    radius: Theme.lockscreenButtonRadius

                    enabled: !root.context.unlockInProgress && root.context.currentText !== ""

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animationDuration
                            easing.type: Theme.easingType
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "Unlock"
                        font: Theme.lockscreenButtonFont
                        color: unlockButton.enabled ? Color.colorOnPrimary : Color.colorOnSurfaceVariant
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: unlockButton.enabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.context.tryUnlock()
                    }
                }
            }

            // Error message
            Label {
                Layout.alignment: Qt.AlignHCenter
                visible: root.context.showFailure
                text: "Incorrect password"
                color: Color.colorError
                font: Theme.lockscreenErrorFont

                opacity: visible ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.animationDuration
                        easing.type: Theme.easingType
                    }
                }
            }
        }
    }
}
