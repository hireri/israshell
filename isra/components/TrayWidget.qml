import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Effects

import qs.components
import qs.style

Item {
    id: root
    required property var panelWindow

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
        yOffset: 14
    }

    TrayMenuWindow {
        id: menu
        panelWindow: root.panelWindow
    }

    Rectangle {
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        width: parent.width
        color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
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

                    readonly property bool blacklisted: Config.trayBlacklist.includes(modelData?.id ?? "") || Config.trayBlacklist.includes(modelData?.title ?? "")
                    visible: !blacklisted
                    width: visible ? 20 : 0
                    implicitWidth: visible ? 20 : 0
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: img
                        source: cell.modelData?.icon ?? ""
                        anchors.fill: parent
                        sourceSize: Qt.size(20, 20)
                        fillMode: Image.PreserveAspectFit
                        visible: !Config.tintTrayIcons
                    }

                    Loader {
                        active: Config.tintTrayIcons
                        anchors.fill: img
                        sourceComponent: MultiEffect {
                            source: img
                            saturation: -1.0
                            colorization: 1.0
                            colorizationColor: Qt.alpha(Colors.md3.on_surface, 0.4)
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
                            var yPos = Config.barPosition === 1 ? 0 : cell.height;
                            tooltip.targetPos = cell.mapToGlobal(cell.width / 2, yPos);
                            tooltip.tipTitle = name;
                            tooltip.visible = true;
                        }
                        onExited: tooltip.visible = false

                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                cell.modelData?.activate();
                            } else if (mouse.button === Qt.RightButton) {
                                tooltip.visible = false;
                                var yEdge = Config.barPosition === 1 ? 0 : cell.height;
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
