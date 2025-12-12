import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import "../../common"

ColumnLayout {
    id: audioInputSelector

    property int currentIndex: -1
    property bool expanded: false

    spacing: 0

    PwObjectTracker {
        id: inputNodeTracker
        objects: {
            const nodes = Pipewire.nodes.values;
            const audioNodes = [];
            for (let i = 0; i < nodes.length; i++) {
                if (nodes[i].audio !== null) {
                    audioNodes.push(nodes[i]);
                }
            }
            return audioNodes;
        }
    }

    ListModel {
        id: audioInputModel
    }

    Timer {
        id: inputRefreshTimer
        interval: Theme.audioSelectorRefreshInterval
        running: true
        repeat: true
        onTriggered: updateSources()
    }

    function updateSources() {
        audioInputModel.clear();
        let currentIdx = -1;
        const nodes = Pipewire.nodes.values;

        for (let i = 0; i < nodes.length; i++) {
            const node = nodes[i];
            if (!node || !node.audio) {
                continue;
            }

            if (!node.isSink && !node.isStream) {
                const desc = node.description || node.properties["node.nick"] || node.properties["node.name"] || "Unknown Device";
                audioInputModel.append({
                    "node": node,
                    "description": desc
                });

                if (Pipewire.defaultAudioSource && node.id === Pipewire.defaultAudioSource.id) {
                    currentIdx = audioInputModel.count - 1;
                }
            }
        }
        audioInputSelector.currentIndex = currentIdx;
    }

    Connections {
        target: Pipewire
        function onNodesChanged() {
            updateSources();
        }
        function onDefaultAudioSourceChanged() {
            updateSources();
        }
    }

    Connections {
        target: inputNodeTracker
        function onObjectsChanged() {
            updateSources();
        }
    }

    Component.onCompleted: updateSources()

    RowLayout {
        id: inputControlRow
        spacing: Theme.audioSelectorSpacing
        Layout.fillWidth: true

        Rectangle {
            id: inputMuteButton

            Layout.preferredWidth: Theme.sliderPrefixWidth
            Layout.preferredHeight: Theme.sliderHeight
            color: inputMuteMouseArea.containsMouse ? Qt.darker(Color.colorSurfaceVariant, 1.3) : Color.colorSurface
            radius: Theme.audioSelectorItemRadius

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationDuration
                    easing.type: Theme.easingType
                }
            }

            Text {
                id: inputMuteIcon
                text: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted) ? "microphone-slash" : "microphone"
                anchors.centerIn: parent
                color: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted) ? Color.colorError : Color.colorOnSurface
                font: Theme.audioSelectorIconFont

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animationDuration
                        easing.type: Theme.easingType
                    }
                }
            }

            MouseArea {
                id: inputMuteMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
                        Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted;
                    }
                }
            }
        }

        Rectangle {
            id: inputSelectorButton

            Layout.fillWidth: true
            Layout.preferredHeight: Theme.sliderHeight
            color: inputSelectorMouseArea.containsMouse ? Qt.darker(Color.colorSurfaceVariant, 1.3) : Color.colorSurface
            radius: Theme.audioSelectorButtonRadius

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationDuration
                    easing.type: Theme.easingType
                }
            }

            RowLayout {
                id: inputSelectorContent
                anchors.fill: parent
                anchors.leftMargin: Theme.audioSelectorButtonHorizontalMargin
                anchors.rightMargin: Theme.audioSelectorButtonHorizontalMargin
                spacing: Theme.audioSelectorButtonInnerSpacing

                Text {
                    id: inputDeviceLabel
                    Layout.fillWidth: true
                    text: audioInputSelector.currentIndex >= 0 ? audioInputModel.get(audioInputSelector.currentIndex).description : "No device"
                    color: Color.colorOnSurface
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    font: Theme.barFont
                }

                Text {
                    id: inputExpandIcon
                    text: audioInputSelector.expanded ? "angle-up" : "angle-down"
                    color: Color.colorOnSurface
                    font: Theme.audioSelectorArrowFont
                }
            }

            MouseArea {
                id: inputSelectorMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: audioInputSelector.expanded = !audioInputSelector.expanded
            }
        }
    }

    Item {
        id: inputListContainer
        Layout.fillWidth: true
        Layout.preferredHeight: audioInputSelector.expanded ? inputDeviceList.contentHeight : 0
        clip: true

        Behavior on Layout.preferredHeight {
            NumberAnimation {
                duration: Theme.audioSelectorExpandDuration
                easing.type: Theme.easingType
            }
        }

        ListView {
            id: inputDeviceList
            anchors.fill: parent
            interactive: false
            model: audioInputModel

            delegate: Rectangle {
                id: inputDeviceItem
                width: inputDeviceList.width
                height: Theme.sliderHeight
                color: inputDeviceMouseArea.containsMouse ? Qt.darker(Color.colorSurfaceVariant, 1.3) : Color.colorSurface
                radius: Theme.audioSelectorItemRadius

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animationDuration
                        easing.type: Theme.easingType
                    }
                }

                RowLayout {
                    id: inputDeviceContent
                    anchors.fill: parent
                    anchors.leftMargin: Theme.sliderPrefixWidth + Theme.audioSelectorItemLeftMarginOffset
                    anchors.rightMargin: Theme.audioSelectorItemRightMargin
                    spacing: Theme.audioSelectorItemSpacing

                    Text {
                        id: inputDeviceNameText
                        Layout.fillWidth: true
                        text: model.description
                        color: index === audioInputSelector.currentIndex ? Color.colorPrimary : Color.colorOnSurface
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        font: Theme.barFont
                    }

                    Text {
                        id: inputDeviceCheckIcon
                        visible: index === audioInputSelector.currentIndex
                        text: "check"
                        color: Color.colorPrimary
                        font: Theme.audioSelectorCheckFont
                    }
                }

                MouseArea {
                    id: inputDeviceMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (model.node) {
                            Pipewire.preferredDefaultAudioSource = model.node;
                            audioInputSelector.expanded = false;
                        }
                    }
                }
            }
        }
    }
}
