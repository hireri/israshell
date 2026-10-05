import QtQuick
import qs.style

Column {
    id: root

    property bool   pm: false
    property color  color
    property string clockFont
    property real   fontSize
    property int    fontWeight
    property bool   isGoogleSansFlex
    property var    axes

    spacing: -root.fontSize * 0.2

    Repeater {
        model: [false, true]

        Text {
            id: label
            required property bool modelData

            readonly property string word: Localization.t(label.modelData ? "clock.pm" : "clock.am")

            anchors.horizontalCenter: parent.horizontalCenter
            text:    Config.hourFormat === 2 ? label.word : label.word.toLowerCase()
            color:   root.color
            opacity: root.pm === label.modelData ? 1.0 : 0.35

            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutCubic } }

            font.family:        root.clockFont
            font.pixelSize:     root.fontSize
            font.weight:        root.isGoogleSansFlex ? Font.Normal : root.fontWeight
            font.letterSpacing: 0.5
            font.variableAxes:  root.isGoogleSansFlex ? root.axes : ({})
        }
    }
}
