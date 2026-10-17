pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.style

Rectangle {
    id: root

    property string title: ""
    property string value: ""
    property string subtitle: ""
    property string tone: "primary"
    property var stats: []

    default property alias actions: actionRow.data

    readonly property color _bg: root.tone === "bad" ? Colors.md3.error_container : root.tone === "warn" ? Colors.md3.tertiary_container : root.tone === "ok" ? Colors.md3.secondary_container : Colors.md3.primary_container
    readonly property color _fg: root.tone === "bad" ? Colors.md3.on_error_container : root.tone === "warn" ? Colors.md3.on_tertiary_container : root.tone === "ok" ? Colors.md3.on_secondary_container : Colors.md3.on_primary_container

    implicitHeight: Math.max(92, content.implicitHeight + 28)
    radius: 18
    color: Config.dim(root._bg)

    Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    RowLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 20
            rightMargin: 20
        }
        spacing: 20

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.value
                font.family: Config.fontFamily
                font.pixelSize: 30
                font.weight: Font.Medium
                color: root._fg
                visible: root.value !== ""
            }

            Text {
                text: root.title
                font.family: Config.fontFamily
                font.pixelSize: 14
                color: root._fg
                visible: root.title !== ""
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: root.subtitle
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: Qt.alpha(root._fg, 0.8)
                visible: root.subtitle !== ""
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        Repeater {
            model: root.stats

            ColumnLayout {
                id: stat
                required property var modelData
                spacing: 0

                Text {
                    text: stat.modelData.value
                    font.family: Config.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    color: root._fg
                }

                Text {
                    text: stat.modelData.label
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    color: Qt.alpha(root._fg, 0.8)
                }
            }
        }

        Row {
            id: actionRow
            spacing: 8
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
