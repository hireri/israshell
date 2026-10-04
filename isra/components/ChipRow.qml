import QtQuick
import qs.style

Row {
    id: root

    property var options: []
    property var currentValue: null
    property bool compact: false
    property bool large: false
    property real fitWidth: 0
    signal selected(var value)

    readonly property real smallRadius: 6
    readonly property real chipHeight: root.large ? 40 : root.compact ? 26 : 30
    readonly property real fullRadius: root.chipHeight / 2

    property int heldIndex: -1

    spacing: 2

    Repeater {
        model: root.options.length

        Rectangle {
            id: chip
            required property int index
            readonly property var modelData: root.options[index]

            readonly property bool active: root.currentValue === modelData.value
            readonly property bool isFirst: index === 0
            readonly property bool isLastChip: index === root.options.length - 1
            readonly property bool hasIcon: modelData.icon !== undefined && modelData.icon !== null

            readonly property real baseWidth: root.fitWidth > 0 ? (root.fitWidth - root.spacing * (root.options.length - 1)) / root.options.length : chipContent.implicitWidth + (hasIcon ? (root.compact ? 22 : 30) : (root.large ? 36 : 24))
            readonly property real growDelta: root.large ? 28 : 20
            readonly property real shrinkDelta: root.options.length > 1 ? (growDelta / (root.options.length - 1)) : 0

            readonly property real targetWidth: {
                if (root.heldIndex === -1) {
                    return baseWidth;
                } else if (root.heldIndex === index) {
                    return baseWidth + growDelta;
                } else {
                    return Math.max(20, baseWidth - shrinkDelta);
                }
            }

            height: root.chipHeight
            width: targetWidth

            color: active ? Colors.md3.primary : (Config.dim(Colors.md3.surface_container_high))

            topLeftRadius: (active || isFirst) ? root.fullRadius : root.smallRadius
            bottomLeftRadius: (active || isFirst) ? root.fullRadius : root.smallRadius
            topRightRadius: (active || isLastChip) ? root.fullRadius : root.smallRadius
            bottomRightRadius: (active || isLastChip) ? root.fullRadius : root.smallRadius

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
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
                    visible: text.length > 0
                    text: chip.modelData.label
                    font.family: Config.fontFamily
                    font.pixelSize: root.large ? 14 : 12
                    font.weight: chip.active ? Font.Medium : Font.Normal
                    color: chip.active ? Colors.md3.on_primary : Colors.md3.on_surface_variant
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                readonly property bool isHeld: pressed && containsMouse

                onIsHeldChanged: {
                    if (isHeld) {
                        root.heldIndex = index;
                    } else if (root.heldIndex === index) {
                        root.heldIndex = -1;
                    }
                }

                onClicked: root.selected(chip.modelData.value)
            }
        }
    }
}
