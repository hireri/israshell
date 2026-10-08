pragma ComponentBehavior: Bound

import QtQuick
import qs.style

Rectangle {
    id: root

    property bool open: false
    property var items: []
    property int currentIndex: 0
    property string emptyText: ""

    readonly property int rowHeight: 40

    signal picked(int index)
    signal hovered(int index)

    implicitHeight: Math.max(1, root.items.length) * root.rowHeight + 16
    radius: 28

    visible: opacity > 0
    opacity: root.open ? 1 : 0
    scale: root.open ? 1 : 0.9
    transformOrigin: Item.Bottom
    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }
    color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
    border.width: 1
    border.color: Colors.md3.outline_variant

    Text {
        visible: root.items.length === 0
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: root.emptyText
        color: Colors.md3.on_surface_variant
        font.pixelSize: 13
        font.family: Config.fontFamily
    }

    Column {
        x: 8
        y: 8
        width: parent.width - 16

        Repeater {
            model: root.items

            Rectangle {
                id: row
                required property var modelData
                required property int index

                width: parent.width
                height: root.rowHeight

                radius: height / 2
                color: row.index === root.currentIndex ? Colors.md3.secondary_container : "transparent"

                Behavior on radius {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 100
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    id: nameText
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.label
                    color: row.index === root.currentIndex ? Colors.md3.on_secondary_container : Colors.md3.primary
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    font.family: Config.fontFamily
                }

                Text {
                    id: hintText
                    anchors.left: nameText.right
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.hint ?? ""
                    color: Colors.md3.on_surface_variant
                    opacity: 0.6
                    font.pixelSize: 13
                    font.family: Config.fontFamily
                }

                Text {
                    anchors.left: hintText.right
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    text: row.modelData.description
                    color: row.index === root.currentIndex ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
                    font.pixelSize: 13
                    font.family: Config.fontFamily
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: root.hovered(row.index)
                    onClicked: root.picked(row.index)
                }
            }
        }
    }
}
