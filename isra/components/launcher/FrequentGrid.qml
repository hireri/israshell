pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.icons

Item {
    id: root

    property var apps: []
    signal launchRequested(var entry)

    readonly property int _cols: 2
    readonly property real _tileW: (width - 20 - 6) / _cols
    readonly property int _rows: Math.max(1, Math.ceil(apps.length / _cols))
    readonly property real _tileH: Math.max(76, Math.min(140, (height - (heading.y + heading.height + 6) - 10 - 6 * (_rows - 1)) / _rows))
    readonly property int _icon: _tileH >= 96 ? 44 : 36

    Text {
        id: heading
        x: 16
        y: 10
        text: Localization.t("launcher.section_frequent")
        color: Colors.md3.primary
        font.pixelSize: 12
        font.family: Config.fontFamily
        font.weight: Font.Medium
    }

    Grid {
        anchors {
            top: heading.bottom
            topMargin: 6
            left: parent.left
            leftMargin: 10
        }
        columns: root._cols
        spacing: 6

        Repeater {
            model: root.apps

            Rectangle {
                id: tile
                required property var modelData
                required property int index

                width: root._tileW
                height: root._tileH
                radius: 16
                color: ma.containsMouse ? Colors.md3.secondary_container : Colors.md3.surface_container_high

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                scale: ma.pressed ? 0.97 : 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }

                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: 12
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 4

                    Item {
                        width: root._icon
                        height: root._icon
                        readonly property string iconName: tile.modelData.icon ?? ""
                        IconImage {
                            anchors.fill: parent
                            asynchronous: true
                            visible: parent.iconName !== ""
                            source: Quickshell.iconPath(parent.iconName, true)
                        }
                        MaterialIcon {
                            anchors.centerIn: parent
                            visible: parent.iconName === ""
                            name: "grid-view"
                            iconSize: 24
                            color: Colors.md3.primary
                        }
                    }

                    Text {
                        width: parent.width
                        text: tile.modelData.name ?? ""
                        color: ma.containsMouse ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                        font.pixelSize: 13
                        font.family: Config.fontFamily
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: 8
                    }
                    width: badge.implicitWidth + 10
                    height: 18
                    radius: 6
                    color: Colors.md3.surface_container
                    opacity: 0.85

                    Text {
                        id: badge
                        anchors.centerIn: parent
                        text: "Alt " + (tile.index + 1)
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 11
                        font.family: Config.fontFamily
                        font.weight: Font.Medium
                    }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launchRequested(tile.modelData)
                }
            }
        }
    }
}
