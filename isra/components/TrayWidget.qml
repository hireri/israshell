import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects

import qs.components
import qs.style

Item {
    id: root
    required property var panelWindow
    property var controllerRegistry: null

    readonly property bool hasItems: (SystemTray.items?.values.length ?? 0) > 0
    readonly property real contentW: trayRow.implicitWidth

    implicitWidth: contentW > 0 ? contentW + 20 : 0
    height: 32
    visible: hasItems || implicitWidth > 0.1

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    function itemName(item) {
        if (!item)
            return "Application";
        for (const v of [item.tooltipTitle, item.title, item.tooltipDescription, item.id]) {
            if (v && !v.includes("chrome_status_icon"))
                return item.id === v ? v.charAt(0).toUpperCase() + v.slice(1) : v;
        }
        return "Application";
    }

    BarTooltip {
        id: tooltip
        panelWindow: root.panelWindow
        yOffset: 4
    }

    TrayMenuWindow {
        id: menu
        panelWindow: root.panelWindow
        controllerRegistry: root.controllerRegistry
    }

    Rectangle {
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        width: parent.width
        color: {
            if (root.isOpen) {
                Colors.md3.secondary_container
            } else if (Config.bar.transparentPills) {
                Qt.alpha(Colors.md3.secondary_container, 0)
            } else { 
                Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
            }
        }   

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        radius: 18
        clip: true

        Row {
            id: trayRow
            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            spacing: 12

            Repeater {
                model: SystemTray.items
                delegate: Item {
                    id: cell
                    required property var modelData

                    readonly property bool blacklisted: Config.bar.trayBlacklist.includes(modelData?.id ?? "") || Config.bar.trayBlacklist.includes(modelData?.title ?? "")
                    visible: !blacklisted
                    width: visible ? 20 : 0
                    implicitWidth: visible ? 20 : 0
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter

                    IconImage {
                        id: img
                        source: cell.modelData?.icon ?? ""
                        anchors.fill: parent
                        implicitSize: Qt.size(64, 64)
                        visible: !Config.tintIcons
                    }

                    Loader {
                        active: Config.tintIcons
                        anchors.fill: img
                        sourceComponent: Colorize {
                            source: img
                            hue: Qt.color(Colors.md3.on_surface).hslHue
                            saturation: Qt.color(Colors.md3.on_surface).hslSaturation
                            lightness: 0.0
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                        onEntered: {
                            var name = root.itemName(cell.modelData);
                            if (!name)
                                return;
                            var yPos = Config.bar.position === 1 ? 0 : cell.height;
                            tooltip.targetPos = cell.mapToGlobal(cell.width / 2, yPos);
                            tooltip.tipTitle = name;
                            tooltip.open = true;
                        }
                        onExited: tooltip.open = false

                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                cell.modelData?.activate();
                            } else if (mouse.button === Qt.RightButton) {
                                tooltip.open = false;
                                var yEdge = Config.bar.position === 1 ? 0 : cell.height;
                                var globalPos = cell.mapToGlobal(cell.width / 2, yEdge);
                                menu.open(cell.modelData, globalPos);
                            }
                        }
                    }
                }
            }
        }
    }
}
