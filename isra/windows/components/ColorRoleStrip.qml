pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.style

ColumnLayout {
    id: root

    property string label: ""
    property var roles: ["primary", "secondary", "tertiary", "error"]
    property string selected: ""
    property color fallback: Colors.md3.primary

    signal picked(string role)

    Layout.fillWidth: true
    Layout.preferredWidth: 0
    spacing: 6

    Text {
        text: root.label
        font.family: Config.fontFamily
        font.pixelSize: 11
        font.weight: Font.Medium
        color: Colors.md3.outline
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: root.roles

            delegate: Rectangle {
                required property string modelData
                required property int index

                readonly property bool isFirst: index === 0
                readonly property bool isLast: index === root.roles.length - 1
                readonly property bool isSelected: root.selected === modelData

                Layout.fillWidth: true
                height: 28
                color: Colors.md3[modelData] ?? root.fallback

                topLeftRadius: isFirst || isSelected ? 14 : 6
                topRightRadius: isLast || isSelected ? 14 : 6
                bottomLeftRadius: isFirst || isSelected ? 14 : 6
                bottomRightRadius: isLast || isSelected ? 14 : 6

                Behavior on topLeftRadius { NumberAnimation { duration: 150 } }
                Behavior on topRightRadius { NumberAnimation { duration: 150 } }
                Behavior on bottomLeftRadius { NumberAnimation { duration: 150 } }
                Behavior on bottomRightRadius { NumberAnimation { duration: 150 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(modelData)
                }
            }
        }
    }
}
