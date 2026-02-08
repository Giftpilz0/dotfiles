import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../common"
import "../data"

PopupWindow {
    id: dashboard

    property PanelWindow anchorWindow

    visible: ShellState.dashboardVisible
    color: "transparent"

    implicitWidth: Theme.dashboardWidth
    implicitHeight: Math.max(Theme.dashboardHeight, dashboardContent.implicitHeight + (Theme.dashboardContentPadding * 2) + (Theme.dashboardMargin * 2))

    property bool hasEntered: false

    HoverHandler {
        id: dashboardHoverHandler
        onHoveredChanged: {
            if (hovered) {
                dashboard.hasEntered = true;
            }
        }
    }

    Timer {
        id: autoCloseTimer
        interval: Theme.dashboardAutoCloseDelay
        running: ShellState.dashboardVisible && dashboard.hasEntered && !dashboardHoverHandler.hovered
        onTriggered: {
            dashboard.hasEntered = false;
            ShellState.dashboardVisible = false;
        }
    }

    anchor.window: anchorWindow
    anchor.rect.x: anchorWindow.width - width
    anchor.rect.y: anchorWindow.height

    Rectangle {
        id: dashboardBackground
        anchors.fill: parent
        color: Color.colorBackground
        radius: Theme.barRadius
        anchors.leftMargin: Theme.dashboardMargin
        anchors.rightMargin: 0
        anchors.topMargin: Theme.dashboardMargin
        anchors.bottomMargin: Theme.dashboardMargin

        ColumnLayout {
            id: dashboardContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.dashboardContentPadding

            // Volume Sliders Section
            ColumnLayout {
                id: slidersSection

                spacing: Theme.dashboardSlidersSpacing
                Layout.alignment: Qt.AlignTop

                // Brightness Slider
                DashboardSliderWidget {
                    id: brightnessSlider

                    visible: GetBrightness.hasDimmableDisplay
                    Layout.fillWidth: true

                    usePrefix: true
                    prefix: GetBrightness.brightnessIcon

                    slider.value: GetBrightness.brightness

                    slider.onMoved: function () {
                        GetBrightness.setBrightness(brightnessSlider.slider.value);
                    }
                }

                // Speaker Volume Slider
                DashboardSliderWidget {
                    id: speakerVolumeSlider

                    Layout.fillWidth: true

                    usePrefix: true
                    prefix: GetAudioOutput.volumeSpeakerIcon

                    slider.value: GetAudioOutput.volumeSpeaker

                    slider.onMoved: function () {
                        GetAudioOutput.setVolumeSpeaker(speakerVolumeSlider.slider.value);
                    }
                }

                // Microphone Volume Slider
                DashboardSliderWidget {
                    id: micVolumeSlider

                    Layout.fillWidth: true

                    usePrefix: true
                    prefix: GetAudioInput.volumeMicIcon

                    slider.value: GetAudioInput.volumeMic

                    slider.onMoved: function () {
                        GetAudioInput.setVolumeMic(micVolumeSlider.slider.value);
                    }
                }
            }

            // Audio Device Choosers Section
            Rectangle {
                id: audioChoosersContainer
                Layout.fillWidth: true
                Layout.topMargin: Theme.dashboardAudioChoosersTopMargin
                Layout.preferredHeight: audioChoosersLayout.implicitHeight + (Theme.dashboardAudioChoosersMargin * 2)
                color: Color.colorSurface
                radius: Theme.dashboardAudioChoosersRadius

                ColumnLayout {
                    id: audioChoosersLayout
                    anchors.fill: parent
                    anchors.margins: Theme.dashboardAudioChoosersMargin
                    spacing: Theme.dashboardAudioChoosersSpacing

                    AudioOutputSelector {
                        id: outputSelector
                    }

                    AudioInputSelector {
                        id: inputSelector
                    }
                }
            }

            // Quick Settings Toggles Section
            Rectangle {
                id: quickSettingsContainer
                Layout.fillWidth: true
                Layout.topMargin: Theme.dashboardQuickSettingsTopMargin
                Layout.preferredHeight: quickSettingsLayout.implicitHeight + (Theme.dashboardQuickSettingsMargin * 2)
                color: Color.colorSurface
                radius: Theme.dashboardQuickSettingsRadius

                GridLayout {
                    id: quickSettingsLayout

                    anchors.fill: parent
                    anchors.margins: Theme.dashboardQuickSettingsMargin

                    columns: 2
                    rowSpacing: Theme.dashboardQuickSettingsGridSpacing
                    columnSpacing: Theme.dashboardQuickSettingsGridSpacing

                    BluetoothToggle {
                        id: bluetoothToggleItem
                    }

                    WiFiToggle {
                        id: wifiToggleItem
                    }

                    EthernetToggle {
                        id: ethernetToggleItem
                    }

                    WallpaperToggle {
                        id: wallpaperToggleItem
                    }
                }
            }
        }
    }
}
