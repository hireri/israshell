pragma ComponentBehavior: Bound

import QtQuick
import qs.style
import qs.icons

Item {
    id: root

    property string tool: ""
    property string color: "#ff3b30"
    property int strokeWidth: 4
    property bool canUndo: false
    property bool canRedo: false
    property bool canDelete: false
    property bool shown: true

    signal toolPicked(string id)
    signal colorPicked(string color)
    signal widthPicked(int width)
    signal deleteRequested
    signal undoRequested
    signal redoRequested
    signal closeRequested

    readonly property var tools: [
        { id: "region", icon: "region" },
        { id: "move", icon: "drag-pan" },
        { id: "rect", icon: "rectangle" },
        { id: "ellipse", icon: "circle" },
        { id: "line", icon: "pen-size-2" },
        { id: "arrow", icon: "arrow-outward" },
        { id: "pen", icon: "stylus" },
        { id: "highlighter", icon: "ink-highlighter" },
        { id: "text", icon: "word-clock" },
        { id: "step", icon: "counter-1" },
        { id: "blur", icon: "blur-on" },
        { id: "pixelate", icon: "grid-on" }
    ]
    readonly property var swatches: ["#ff3b30", "#ffcc00", "#34c759", "#0a84ff", "#000000", "#ffffff"]
    readonly property var widthOptions: [
        { value: 2, dot: 4 },
        { value: 4, dot: 7 },
        { value: 8, dot: 11 }
    ]
    readonly property int toolIndex: tools.findIndex(t => t.id === tool)

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 56

    MouseArea {
        anchors.fill: parent
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Colors.md3.surface_container
        border.width: 1
        border.color: Colors.md3.outline_variant
    }

    Row {
        id: row
        anchors.centerIn: parent

        Item {
            width: root.tools.length * 44
            height: 56

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: 40
                radius: height / 2
                color: Colors.md3.surface_container_highest

                Rectangle {
                    x: Math.max(0, root.toolIndex) * 44 + 4
                    y: 4
                    width: 36
                    height: 32
                    radius: height / 2
                    color: Colors.md3.secondary
                    opacity: root.toolIndex >= 0 ? 1.0 : 0.0
                    Behavior on x {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Row {
                    anchors.fill: parent
                    Repeater {
                        model: root.tools
                        Item {
                            required property var modelData
                            readonly property bool isActive: root.tool === modelData.id
                            width: 44
                            height: 40

                            MaterialIcon {
                                anchors.centerIn: parent
                                name: modelData.icon
                                iconSize: 20
                                color: isActive ? Colors.md3.on_secondary : Colors.md3.on_surface
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toolPicked(modelData.id)
                            }
                            Tooltip {
                                flat: true
                                text: Localization.t("screenshot.tip_" + modelData.id)
                                suppressed: !root.shown
                            }
                        }
                    }
                }
            }
        }

        Item {
            width: 17
            height: 56
            Rectangle {
                anchors.centerIn: parent
                width: 1
                height: 28
                color: Colors.md3.outline_variant
                opacity: 0.6
            }
        }

        Item {
            width: root.swatches.length * 32
            height: 56

            Row {
                anchors.centerIn: parent
                Repeater {
                    model: root.swatches
                    Item {
                        required property var modelData
                        readonly property bool selected: root.color.toLowerCase() === modelData
                        width: 32
                        height: 32

                        Rectangle {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            radius: 10
                            color: modelData
                            border.width: 1
                            border.color: Colors.md3.outline_variant
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 26
                            height: 26
                            radius: 13
                            color: "transparent"
                            border.width: 2
                            border.color: Colors.md3.on_surface
                            visible: selected
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.colorPicked(modelData)
                        }
                    }
                }
            }
        }

        Item {
            width: 17
            height: 56
            Rectangle {
                anchors.centerIn: parent
                width: 1
                height: 28
                color: Colors.md3.outline_variant
                opacity: 0.6
            }
        }

        Item {
            width: root.widthOptions.length * 32
            height: 56

            Row {
                anchors.centerIn: parent
                Repeater {
                    model: root.widthOptions
                    Item {
                        required property var modelData
                        readonly property bool selected: root.strokeWidth === modelData.value
                        width: 32
                        height: 32

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            radius: 14
                            color: Colors.md3.secondary_container
                            visible: selected
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: modelData.dot
                            height: modelData.dot
                            radius: width / 2
                            color: Colors.md3.on_surface
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.widthPicked(modelData.value)
                        }
                        Tooltip {
                            flat: true
                            text: Localization.t("screenshot.tip_width_" + modelData.value)
                            suppressed: !root.shown
                        }
                    }
                }
            }
        }

        Item {
            width: 17
            height: 56
            Rectangle {
                anchors.centerIn: parent
                width: 1
                height: 28
                color: Colors.md3.outline_variant
                opacity: 0.6
            }
        }

        Item {
            width: root.canDelete ? 40 : 0
            opacity: root.canDelete ? 1.0 : 0.0
            visible: width > 0
            clip: true
            Behavior on width {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
            height: 56

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                x: (40 - width) / 2
                name: "delete"
                iconSize: 20
                color: Colors.md3.on_surface
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.canDelete
                cursorShape: Qt.PointingHandCursor
                onClicked: root.deleteRequested()
            }
            Tooltip {
                flat: true
                text: Localization.t("screenshot.tip_delete")
                suppressed: !root.shown
            }
        }

        Item {
            width: 40
            height: 56
            opacity: root.canUndo ? 1.0 : 0.38
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                name: "undo"
                iconSize: 20
                color: Colors.md3.on_surface
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.canUndo
                cursorShape: Qt.PointingHandCursor
                onClicked: root.undoRequested()
            }
            Tooltip {
                flat: true
                text: Localization.t("screenshot.tip_undo")
                suppressed: !root.shown
            }
        }

        Item {
            width: 40
            height: 56
            opacity: root.canRedo ? 1.0 : 0.38
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                name: "redo"
                iconSize: 20
                color: Colors.md3.on_surface
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.canRedo
                cursorShape: Qt.PointingHandCursor
                onClicked: root.redoRequested()
            }
            Tooltip {
                flat: true
                text: Localization.t("screenshot.tip_redo")
                suppressed: !root.shown
            }
        }

        Item {
            width: 17
            height: 56
            Rectangle {
                anchors.centerIn: parent
                width: 1
                height: 28
                color: Colors.md3.outline_variant
                opacity: 0.6
            }
        }

        Item {
            width: 40
            height: 56

            Rectangle {
                anchors.centerIn: parent
                width: 36
                height: 36
                radius: 18
                color: closeMouse.containsMouse ? Colors.md3.surface_variant : Colors.md3.surface_container
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    name: "close"
                    iconSize: 20
                    color: Colors.md3.on_surface_variant
                }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
            Tooltip {
                flat: true
                text: Localization.t("screenshot.tip_close")
                suppressed: !root.shown
            }
        }
    }
}
