import QtQuick
import qs.style

SettingRow {
    id: root

    property var options: []
    property var currentValue: null
    signal selected(var value)

    property bool isLast: false

    property Component icon: null

    readonly property real smallRadius: 6
    readonly property real fullRadius: 15

    Row {
        spacing: 10
        anchors.verticalCenter: parent?.verticalCenter

        Loader {
            active: root.icon !== null
            sourceComponent: root.icon
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: root.options

                Rectangle {
                    id: chip
                    required property var modelData
                    required property int index

                    readonly property bool active: root.currentValue === modelData.value
                    readonly property bool isFirst: index === 0
                    readonly property bool isLastChip: index === root.options.length - 1
                    readonly property bool hasIcon: modelData.icon !== undefined && modelData.icon !== null

                    height: 30
                    width: chipContent.implicitWidth + (hasIcon ? 30 : 24)

                    color: active ? Colors.md3.primary : Colors.md3.surface_container_high

                    topLeftRadius: (active || isFirst) ? root.fullRadius : root.smallRadius
                    bottomLeftRadius: (active || isFirst) ? root.fullRadius : root.smallRadius
                    topRightRadius: (active || isLastChip) ? root.fullRadius : root.smallRadius
                    bottomRightRadius: (active || isLastChip) ? root.fullRadius : root.smallRadius

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                    Behavior on topLeftRadius {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                    Behavior on bottomLeftRadius {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                    Behavior on topRightRadius {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                    Behavior on bottomRightRadius {
                        NumberAnimation {
                            duration: 120
                        }
                    }

                    Row {
                        id: chipContent
                        anchors.centerIn: parent
                        spacing: 6

                        Loader {
                            active: chip.hasIcon
                            sourceComponent: chip.hasIcon ? chip.modelData.icon : null
                            anchors.verticalCenter: parent.verticalCenter

                            property bool iconActive: chip.active
                            onLoaded: {
                                if (item && item.hasOwnProperty("color"))
                                    item.color = Qt.binding(() => chip.active ? Colors.md3.on_primary : Colors.md3.on_surface_variant);
                            }
                        }

                        Text {
                            id: chipLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: chip.modelData.label
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: chip.active ? Font.Medium : Font.Normal
                            color: chip.active ? Colors.md3.on_primary : Colors.md3.on_surface_variant
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentValue = chip.modelData.value;
                            root.selected(chip.modelData.value);
                        }
                    }
                }
            }
        }
    }
}
