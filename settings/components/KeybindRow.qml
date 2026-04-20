import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string action: ""
    property var keys: []
    property bool isLast: false

    implicitHeight: 48
    implicitWidth: parent?.width ?? 0

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 18
        height: 1
        color: Colors.md3.outline_variant
        visible: !root.isLast
        opacity: 0.5
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 18
            rightMargin: 18
        }

        Text {
            text: root.action
            font.family: Config.fontFamily
            font.pixelSize: 13
            color: Colors.md3.on_surface
            Layout.fillWidth: true
        }

        Row {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: root.keys

                Rectangle {
                    required property string modelData
                    height: 24
                    width: keyText.implicitWidth + 16
                    radius: 4
                    color: Colors.md3.surface_container_high
                    border.width: 1
                    border.color: Colors.md3.surface_variant

                    Text {
                        id: keyText
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Config.fontMonospace
                        font.pixelSize: 11
                        color: Colors.md3.on_surface_variant
                    }
                }
            }
        }
    }
}
