import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../../common"

RowLayout {
    id: sliderWidget

    property bool usePrefix: false
    property string prefix: ""
    property alias slider: valueSlider

    spacing: Theme.sliderSpacing

    Rectangle {
        id: prefixContainer
        color: "transparent"
        Layout.preferredWidth: Theme.sliderPrefixWidth
        height: Theme.sliderHeight

        Text {
            id: prefixIcon
            text: sliderWidget.prefix
            visible: sliderWidget.usePrefix
            anchors.centerIn: parent
            color: Color.colorOnSurface
            font: Theme.sliderPrefixIconFont
        }
    }

    Slider {
        id: valueSlider

        from: 0
        to: 100
        value: 0

        Layout.fillWidth: true
        height: Theme.sliderHeight

        background: Rectangle {
            id: sliderBackground

            color: Color.colorSurface
            radius: Theme.sliderRadius

            Text {
                id: sliderValueText

                text: Math.round(valueSlider.value)
                anchors.centerIn: sliderBackground
                color: Color.colorOnSurfaceVariant
                font: Theme.sliderValueFont
            }

            Rectangle {
                id: sliderFillBar
                width: valueSlider.visualPosition * valueSlider.width
                height: (valueSlider.height > width) ? width : valueSlider.height
                anchors.verticalCenter: parent.verticalCenter
                color: Color.colorPrimary
                radius: Theme.sliderRadius
                clip: true

                Text {
                    id: sliderValueTextOverlay
                    text: sliderValueText.text
                    x: sliderValueText.x
                    y: sliderValueText.y
                    color: Color.colorOnPrimary
                    font: Theme.sliderValueFont
                }
            }
        }

        handle: Item {
            visible: false
        }
    }
}
