pragma ComponentBehavior: Bound

import QtQuick
import qs.icons
import qs.style

Rectangle {
    id: root

    property bool open: false
    property var items: []
    property int currentIndex: 0
    property string emptyText: ""

    readonly property int rowHeight: 48
    readonly property int labelColumn: 128

    signal picked(int index)
    signal hovered(int index)

    implicitHeight: Math.max(1, root.items.length) * root.rowHeight + 16
    radius: 28
    clip: true

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

                readonly property bool current: row.index === root.currentIndex
                readonly property bool pressed: area.pressed

                radius: row.current ? 24 : 16
                color: row.current ? Colors.md3.secondary_container : "transparent"

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

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Colors.md3.on_secondary_container
                    opacity: row.pressed ? 0.10 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    id: chip
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    radius: row.current ? 10 : 16
                    color: row.current ? Colors.md3.primary : Colors.md3.secondary_container

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

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: row.modelData.icon ?? "chevron-right"
                        iconSize: 18
                        transitionType: "none"
                        color: row.current ? Colors.md3.on_primary : Colors.md3.on_secondary_container
                    }
                }

                Row {
                    id: labelRow
                    anchors.left: chip.right
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.labelColumn
                    spacing: 6

                    Text {
                        id: nameText
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.label
                        color: row.current ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        font.family: Config.fontFamily
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.hint ?? ""
                        color: Colors.md3.on_surface_variant
                        opacity: 0.7
                        font.pixelSize: 12
                        font.family: Config.fontFamily
                    }
                }

                Text {
                    anchors.left: labelRow.right
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: row.modelData.description
                    color: row.current ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
                    font.pixelSize: 13
                    font.family: Config.fontFamily
                }

                MouseArea {
                    id: area
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
