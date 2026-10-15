pragma ComponentBehavior: Bound

import QtQuick
import qs.style
import qs.icons
import qs.components.ai

Item {
    id: root

    property string tool: ""
    property string color: "#ff3b30"
    property int strokeWidth: 4
    property bool fill: false
    property string fillShape: ""
    property bool canUndo: false
    property bool canRedo: false
    property bool canDelete: false
    property bool shown: true

    signal toolPicked(string id)
    signal colorPicked(string color)
    signal widthPicked(int width)
    signal fillPicked(bool fill)
    signal deleteRequested
    signal undoRequested
    signal redoRequested
    signal closeRequested

    readonly property var tools: [
        { id: "region", icon: "region" },
        { id: "move", icon: "drag-pan" },
        { id: "rect", icon: "rectangle", fillable: true },
        { id: "ellipse", icon: "circle", fillable: true },
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
    readonly property var widths: [{ value: 2, bar: 2 }, { value: 4, bar: 4 }, { value: 8, bar: 7 }]
    readonly property int toolIndex: tools.findIndex(t => t.id === tool)
    readonly property int swatchIndex: swatches.indexOf(color.toLowerCase())
    readonly property int styleIndex: fill && fillShape !== "" ? widths.length : widths.findIndex(w => w.value === strokeWidth)

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
        spacing: 8

        Rectangle {
            width: root.tools.length * 44
            height: 40
            radius: 20
            color: Colors.md3.surface_container_highest

            SlidingIndicator {
                id: toolInd
                index: root.toolIndex
                step: 44
                color: Colors.md3.secondary
            }

            Row {
                Repeater {
                    model: root.tools
                    Item {
                        id: toolCell
                        required property var modelData
                        readonly property bool active: root.tool === modelData.id
                        width: 44
                        height: 40

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: height / 2
                            color: Colors.md3.on_surface
                            opacity: toolMouse.containsMouse && !toolCell.active ? 0.08 : 0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 100
                                }
                            }
                        }
                        MaterialIcon {
                            anchors.centerIn: parent
                            name: toolCell.modelData.icon
                            filled: root.fill && toolCell.modelData.fillable === true
                            transitionType: "circle"
                            iconSize: 20
                            scale: toolMouse.pressed ? 0.85 : 1
                            color: toolInd.covers(toolCell.x + toolCell.width / 2) ? Colors.md3.on_secondary : Colors.md3.on_surface
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        MouseArea {
                            id: toolMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toolPicked(toolCell.modelData.id)
                        }
                        Tooltip {
                            flat: true
                            text: Localization.t("screenshot.tip_" + toolCell.modelData.id)
                            suppressed: !root.shown
                        }
                    }
                }
            }
        }

        Rectangle {
            width: root.swatches.length * 40
            height: 40
            radius: 20
            color: Colors.md3.surface_container_highest

            SlidingIndicator {
                index: root.swatchIndex
                step: 40
                color: Colors.md3.secondary
            }

            Row {
                Repeater {
                    model: root.swatches
                    Item {
                        id: swatch
                        required property string modelData
                        required property int index
                        readonly property bool active: root.swatchIndex === index
                        width: 40
                        height: 40

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: height / 2
                            color: Colors.md3.on_surface
                            opacity: swatchMouse.containsMouse && !swatch.active ? 0.08 : 0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 100
                                }
                            }
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            radius: 10
                            scale: swatchMouse.pressed ? 0.8 : 1
                            color: swatch.modelData
                            border.width: 1
                            border.color: Qt.alpha(Colors.md3.on_surface, 0.16)
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        MouseArea {
                            id: swatchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.colorPicked(swatch.modelData)
                        }
                    }
                }
            }
        }

        Rectangle {
            width: styleRow.width
            height: 40
            radius: 20
            color: Colors.md3.surface_container_highest

            SlidingIndicator {
                id: styleInd
                index: root.styleIndex
                step: 40
                color: Colors.md3.secondary
            }

            Row {
                id: styleRow

                Repeater {
                    model: root.widths
                    Item {
                        id: widthCell
                        required property var modelData
                        required property int index
                        readonly property bool active: root.styleIndex === index
                        width: 40
                        height: 40

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: height / 2
                            color: Colors.md3.on_surface
                            opacity: widthMouse.containsMouse && !widthCell.active ? 0.08 : 0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 100
                                }
                            }
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 16
                            height: widthCell.modelData.bar
                            radius: height / 2
                            rotation: -45
                            scale: widthMouse.pressed ? 0.8 : 1
                            color: styleInd.covers(widthCell.x + widthCell.width / 2) ? Colors.md3.on_secondary : Colors.md3.on_surface
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        MouseArea {
                            id: widthMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.widthPicked(widthCell.modelData.value)
                        }
                        Tooltip {
                            flat: true
                            text: Localization.t("screenshot.tip_width_" + widthCell.modelData.value)
                            suppressed: !root.shown
                        }
                    }
                }

                Item {
                    id: fillCell
                    readonly property bool active: root.styleIndex === root.widths.length
                    width: root.fillShape !== "" ? 40 : 0
                    height: 40
                    clip: true
                    Behavior on width {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        x: 4
                        y: 4
                        width: 32
                        height: 32
                        radius: 16
                        color: Colors.md3.on_surface
                        opacity: fillMouse.containsMouse && !fillCell.active ? 0.08 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 100
                            }
                        }
                    }
                    MaterialIcon {
                        x: (40 - width) / 2
                        anchors.verticalCenter: parent.verticalCenter
                        name: root.fillShape === "ellipse" ? "circle" : "rectangle"
                        filled: true
                        transitionType: "none"
                        iconSize: 18
                        scale: fillMouse.pressed ? 0.8 : 1
                        color: styleInd.covers(fillCell.x + 20) ? Colors.md3.on_secondary : Colors.md3.on_surface
                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    MouseArea {
                        id: fillMouse
                        anchors.fill: parent
                        enabled: root.fillShape !== ""
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.fillPicked(!root.fill)
                    }
                    Tooltip {
                        flat: true
                        text: Localization.t("screenshot.tip_fill")
                        suppressed: !root.shown || root.fillShape === ""
                    }
                }
            }
        }

        Row {
            Item {
                width: root.canDelete ? 44 : 0
                height: 40
                clip: true
                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                MorphButton {
                    icon: "delete"
                    enabled: root.canDelete
                    container: Colors.md3.surface_container_highest
                    content: Colors.md3.on_surface
                    onClicked: root.deleteRequested()
                    Tooltip {
                        flat: true
                        text: Localization.t("screenshot.tip_delete")
                        suppressed: !root.shown
                    }
                }
            }

            MorphButton {
                icon: "undo"
                enabled: root.canUndo
                opacity: enabled ? 1 : 0.38
                container: Colors.md3.surface_container_highest
                content: Colors.md3.on_surface
                onClicked: root.undoRequested()
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }
                Tooltip {
                    flat: true
                    text: Localization.t("screenshot.tip_undo")
                    suppressed: !root.shown
                }
            }

            Item {
                width: 4
                height: 40
            }

            MorphButton {
                icon: "redo"
                enabled: root.canRedo
                opacity: enabled ? 1 : 0.38
                container: Colors.md3.surface_container_highest
                content: Colors.md3.on_surface
                onClicked: root.redoRequested()
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }
                Tooltip {
                    flat: true
                    text: Localization.t("screenshot.tip_redo")
                    suppressed: !root.shown
                }
            }
        }

        MorphButton {
            icon: "close"
            container: Colors.md3.surface_container_highest
            content: Colors.md3.on_surface_variant
            onClicked: root.closeRequested()
            Tooltip {
                flat: true
                text: Localization.t("screenshot.tip_close")
                suppressed: !root.shown
            }
        }
    }
}
