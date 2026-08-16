pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string iconSource: ""
    property color iconBg: Colors.md3.primary_container
    property string label: ""
    property string sublabel: ""

    property bool isLast: false

    property bool compact: false
    property bool stack: false

    readonly property real sideMargin: root.compact ? 14 : 18
    readonly property real contentWidth: root.width - root.sideMargin * 2

    default property alias content: trailingSlot.data

    implicitHeight: Math.max(root.compact ? 44 : 56, contentCol.implicitHeight + (root.compact ? 14 : 20))
    implicitWidth: parent?.width ?? 0

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: root.sideMargin
        anchors.right: parent.right
        anchors.rightMargin: root.sideMargin
        height: 1
        color: Colors.md3.outline_variant
        visible: !root.isLast
        opacity: 0.5
    }

    ColumnLayout {
        id: contentCol
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: root.sideMargin
            rightMargin: root.sideMargin
            verticalCenter: parent.verticalCenter
        }
        spacing: root.stack ? 6 : 0

        RowLayout {
            id: contentRow
            Layout.fillWidth: true
            spacing: root.compact ? 10 : 14

            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: root.iconBg
                visible: root.iconSource !== ""
                Layout.alignment: Qt.AlignVCenter

                Image {
                    anchors.centerIn: parent
                    source: root.iconSource
                    width: 18
                    height: 18
                    smooth: true
                    asynchronous: true
                    cache: true
                    sourceSize: Qt.size(36, 36)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                visible: root.label !== ""

                Text {
                    text: root.label
                    font.family: Config.fontFamily
                    font.pixelSize: root.compact ? 12 : 13
                    color: Colors.md3.on_surface
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: root.sublabel
                    font.family: Config.fontFamily
                    font.pixelSize: root.compact ? 10 : 11
                    color: Colors.md3.outline
                    visible: root.sublabel !== ""
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }
    }

    Row {
        id: trailingSlot
        parent: root.stack ? contentCol : contentRow
        Layout.alignment: Qt.AlignVCenter
        spacing: 8
    }
}
