import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import "../../common"

ColumnLayout {
    id: audioOutputSelector

    property int currentIndex: -1
    property bool expanded: false

    spacing: 0

    PwObjectTracker {
        id: outputNodeTracker
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
        id: audioOutputModel
    }

    Timer {
        id: outputRefreshTimer
        interval: Theme.audioSelectorRefreshInterval
        running: true
        repeat: true
        onTriggered: updateSinks()
    }

    function updateSinks() {
        audioOutputModel.clear();
        let currentIdx = -1;
        const nodes = Pipewire.nodes.values;

        for (let i = 0; i < nodes.length; i++) {
            const node = nodes[i];
            if (!node || !node.audio) {
                continue;
            }

            if (node.isSink && !node.isStream) {
                const desc = node.description || node.properties["node.nick"] || node.properties["node.name"] || "Unknown Device";
                audioOutputModel.append({
                    "node": node,
                    "description": desc
                });

                if (Pipewire.defaultAudioSink && node.id === Pipewire.defaultAudioSink.id) {
                    currentIdx = audioOutputModel.count - 1;
                }
            }
        }
        audioOutputSelector.currentIndex = currentIdx;
    }

    Connections {
        target: Pipewire
        function onNodesChanged() {
            updateSinks();
        }
        function onDefaultAudioSinkChanged() {
            updateSinks();
        }
    }

    Connections {
        target: outputNodeTracker
        function onObjectsChanged() {
            updateSinks();
        }
    }

    Component.onCompleted: updateSinks()

    RowLayout {
        id: outputControlRow
        spacing: Theme.audioSelectorSpacing
        Layout.fillWidth: true

        Rectangle {
            id: outputMuteButton

            Layout.preferredWidth: Theme.sliderPrefixWidth
            Layout.preferredHeight: Theme.sliderHeight
            color: outputMuteMouseArea.containsMouse ? Qt.darker(Color.colorSurfaceVariant, 1.3) : Color.colorSurface
            radius: Theme.audioSelectorItemRadius

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationDuration
                    easing.type: Theme.easingType
                }
            }

            Text {
                id: outputMuteIcon
                text: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted) ? "volume-xmark" : "volume-high"
                anchors.centerIn: parent
                color: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted) ? Color.colorError : Color.colorOnSurface
                font: Theme.audioSelectorIconFont

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animationDuration
                        easing.type: Theme.easingType
                    }
                }
            }

            MouseArea {
                id: outputMuteMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                        Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
                    }
                }
            }
        }

        Rectangle {
            id: outputSelectorButton

            Layout.fillWidth: true
            Layout.preferredHeight: Theme.sliderHeight
            color: outputSelectorMouseArea.containsMouse ? Qt.darker(Color.colorSurfaceVariant, 1.3) : Color.colorSurface
            radius: Theme.audioSelectorButtonRadius

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationDuration
                    easing.type: Theme.easingType
                }
            }

            RowLayout {
                id: outputSelectorContent
                anchors.fill: parent
                anchors.leftMargin: Theme.audioSelectorButtonHorizontalMargin
                anchors.rightMargin: Theme.audioSelectorButtonHorizontalMargin
                spacing: Theme.audioSelectorButtonInnerSpacing

                Text {
                    id: outputDeviceLabel
                    Layout.fillWidth: true
                    text: audioOutputSelector.currentIndex >= 0 ? audioOutputModel.get(audioOutputSelector.currentIndex).description : "No device"
                    color: Color.colorOnSurface
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    font: Theme.barFont
                }

                Text {
                    id: outputExpandIcon
                    text: audioOutputSelector.expanded ? "angle-up" : "angle-down"
                    color: Color.colorOnSurface
                    font: Theme.audioSelectorArrowFont
                }
            }

            MouseArea {
                id: outputSelectorMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: audioOutputSelector.expanded = !audioOutputSelector.expanded
            }
        }
    }

    Item {
        id: outputListContainer
        Layout.fillWidth: true
        Layout.preferredHeight: audioOutputSelector.expanded ? outputDeviceList.contentHeight : 0
        clip: true

        Behavior on Layout.preferredHeight {
            NumberAnimation {
                duration: Theme.audioSelectorExpandDuration
                easing.type: Theme.easingType
            }
        }

        ListView {
            id: outputDeviceList
            anchors.fill: parent
            interactive: false
            model: audioOutputModel

            delegate: Rectangle {
                id: outputDeviceItem
                width: outputDeviceList.width
                height: Theme.sliderHeight
                color: outputDeviceMouseArea.containsMouse ? Qt.darker(Color.colorSurfaceVariant, 1.3) : Color.colorSurface
                radius: Theme.audioSelectorItemRadius

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animationDuration
                        easing.type: Theme.easingType
                    }
                }

                RowLayout {
                    id: outputDeviceContent
                    anchors.fill: parent
                    anchors.leftMargin: Theme.sliderPrefixWidth + Theme.audioSelectorItemLeftMarginOffset
                    anchors.rightMargin: Theme.audioSelectorItemRightMargin
                    spacing: Theme.audioSelectorItemSpacing

                    Text {
                        id: outputDeviceNameText
                        Layout.fillWidth: true
                        text: model.description
                        color: index === audioOutputSelector.currentIndex ? Color.colorPrimary : Color.colorOnSurface
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        font: Theme.barFont
                    }

                    Text {
                        id: outputDeviceCheckIcon
                        visible: index === audioOutputSelector.currentIndex
                        text: "check"
                        color: Color.colorPrimary
                        font: Theme.audioSelectorCheckFont
                    }
                }

                MouseArea {
                    id: outputDeviceMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (model.node) {
                            Pipewire.preferredDefaultAudioSink = model.node;
                            audioOutputSelector.expanded = false;
                        }
                    }
                }
            }
        }
    }
}
