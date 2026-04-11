import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import Quickshell
import Quickshell.Services.Polkit

import "../../common"

FloatingWindow {
    id: root

    required property PolkitAgent polkitAgent
    property AuthFlow authFlow: polkitAgent.flow

    color: "transparent"
    width: Theme.polkitDialogWidth
    height: Theme.polkitDialogHeight

    Rectangle {
        anchors.fill: parent
        color: Color.colorBackground
        radius: Theme.polkitDialogRadius

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - (Theme.polkitDialogPadding * 2)
            spacing: Theme.polkitDialogSpacing

            Text {
                Layout.alignment: Qt.AlignHCenter
                font: Theme.polkitDialogIconFont
                color: Color.colorPrimary
                text: "\uf3ed"
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font: Theme.polkitDialogTitleFont
                color: Color.colorOnBackground
                text: "Authentication Required"
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font: Theme.polkitDialogMessageFont
                color: Color.colorOnSurfaceVariant
                text: authFlow && authFlow.message ? authFlow.message : ""
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.polkitDialogInputHeight
                Layout.topMargin: Theme.polkitDialogInputTopMargin
                color: Color.colorSurface
                radius: Theme.polkitDialogInputRadius

                TextField {
                    id: passwordField
                    anchors.fill: parent
                    anchors.margins: 12

                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData
                    placeholderText: authFlow && authFlow.prompt ? authFlow.prompt : "Enter password"

                    font: Theme.polkitDialogInputFont
                    color: Color.colorOnSurface
                    placeholderTextColor: Color.colorOnSurfaceVariant
                    background: Rectangle {
                        color: "transparent"
                    }

                    enabled: authFlow !== null

                    function submitIfPossible() {
                        if (!authFlow)
                            return;
                        if (passwordField.text.length === 0)
                            return;

                        authFlow.submit(passwordField.text);
                        passwordField.text = "";
                    }

                    onAccepted: submitIfPossible()
                    Keys.onEscapePressed: root.visible = false
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Theme.polkitDialogButtonTopMargin
                spacing: Theme.polkitDialogButtonSpacing

                Rectangle {
                    id: closeButton
                    Layout.preferredWidth: Theme.polkitDialogButtonWidth
                    Layout.preferredHeight: Theme.polkitDialogButtonHeight
                    color: Color.colorSurfaceVariant
                    radius: Theme.polkitDialogButtonRadius

                    Label {
                        anchors.centerIn: parent
                        text: "Close"
                        font: Theme.polkitDialogButtonFont
                        color: Color.colorOnSurfaceVariant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: closeButton.color = Color.colorOutline
                        onExited: closeButton.color = Color.colorSurfaceVariant
                        onClicked: root.visible = false
                    }
                }

                Rectangle {
                    id: authButton
                    Layout.preferredWidth: Theme.polkitDialogButtonWidth
                    Layout.preferredHeight: Theme.polkitDialogButtonHeight
                    color: enabled ? Color.colorPrimary : Color.colorSurfaceVariant
                    radius: Theme.polkitDialogButtonRadius

                    enabled: authFlow !== null && passwordField.text.length > 0

                    Label {
                        anchors.centerIn: parent
                        text: "Authenticate"
                        font: Theme.polkitDialogButtonFont
                        color: authButton.enabled ? Color.colorOnPrimary : Color.colorOnSurfaceVariant
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: authButton.enabled
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onEntered: if (enabled)
                            authButton.color = Color.colorPrimaryContainer
                        onExited: authButton.color = enabled ? Color.colorPrimary : Color.colorSurfaceVariant

                        onClicked: passwordField.submitIfPossible()
                    }
                }
            }
        }
    }
}
