import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

import qs.style

Rectangle {
    id: root
    required property var panelWindow

    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
    radius: 18
    implicitWidth: workspacesContent.implicitWidth + 10
    height: 32

    property var currentMonitor: Hyprland.monitorFor(panelWindow.modelData)

    property int activeWorkspaceId: {
        if (!currentMonitor)
            return 1;
        const ws = Hyprland.workspaces.values.find(w => w.active && w.monitor === currentMonitor);
        return ws ? ws.id : 1;
    }

    property int activeIndex: Math.max(0, Math.min(activeWorkspaceId - 1, 9))

    HoverHandler {
        id: rootHover
    }
    property bool isHovered: rootHover.hovered || mainMouseArea.containsMouse

    function getAppId(w) {
        if (!w)
            return "";
        return w.wayland?.appId || w.lastIpcObject?.class || w.lastIpcObject?.initialClass || "";
    }

    function getIconSource(appId) {
        if (!appId)
            return "";
        if (appId.startsWith("steam_app_")) {
            const steamId = appId.replace("steam_app_", "");
            return "image://icon/steam_icon_" + steamId + "?fallback=steam";
        }
        const entry = DesktopEntries.heuristicLookup(appId);
        if (entry && entry.icon) {
            return "image://icon/" + entry.icon + "?fallback=application-x-executable";
        }
        return "image://icon/" + appId + "?fallback=application-x-executable";
    }

    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true

        onWheel: wheel => {
            if (!root.currentMonitor)
                return;
            const currentId = root.activeWorkspaceId;
            const direction = wheel.angleDelta.y > 0 ? -1 : 1;
            const otherMonitorWorkspaces = new Set(Hyprland.workspaces.values.filter(w => w.monitor && w.monitor !== root.currentMonitor).map(w => w.id));

            let target = currentId;
            let attempts = 0;
            do {
                target += direction;
                if (target > 10)
                    target = 1;
                if (target < 1)
                    target = 10;
                if (++attempts > 10)
                    return;
            } while (otherMonitorWorkspaces.has(target) && target !== currentId)

            if (target !== currentId && !otherMonitorWorkspaces.has(target))
                Hyprland.dispatch("workspace " + target);
        }
    }

    Item {
        id: workspacesContent
        anchors.centerIn: parent
        implicitWidth: row.implicitWidth
        height: 24

        Rectangle {
            id: activeIndicator
            width: 24
            height: 24
            radius: 12
            color: Colors.md3.primary

            x: root.activeIndex * 32
            y: 0

            Behavior on x {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
        }

        Row {
            id: row
            spacing: 8

            Repeater {
                model: 10

                Item {
                    id: wsItem
                    width: 24
                    height: 24

                    property int wsId: index + 1

                    property var wsObj: Hyprland.workspaces.values.find(w => w.id === wsId)
                    property bool isActiveHere: root.activeWorkspaceId === wsId
                    property bool isActiveOther: wsObj !== undefined && wsObj.active && wsObj.monitor !== root.currentMonitor

                    property var firstToplevel: Hyprland.toplevels.values.find(t => t.workspace && t.workspace.id === wsId)
                    property bool hasWindows: firstToplevel !== undefined

                    property string clientAppId: root.getAppId(firstToplevel)
                    property string iconPath: root.getIconSource(clientAppId)

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: Colors.md3.on_surface
                        opacity: (itemMouseArea.containsMouse && !wsItem.isActiveHere) ? 0.08 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 4
                            height: 4
                            radius: 3
                            color: Colors.md3.outline_variant

                            property bool showDot: !root.isHovered && !wsItem.isActiveHere && !wsItem.isActiveOther && !wsItem.hasWindows

                            opacity: showDot ? 1 : 0
                            scale: showDot ? 1 : 0.5

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: wsItem.wsId

                            color: {
                                if (wsItem.isActiveHere)
                                    return Colors.md3.on_primary;
                                if (wsItem.isActiveOther)
                                    return Colors.md3.on_surface;
                                return Qt.alpha(Colors.md3.on_surface, 0.4);
                            }
                            font.pixelSize: 13
                            font.bold: true
                            font.family: Config.fontFamily
                            z: 2

                            property bool showNumber: !wsItem.hasWindows && (root.isHovered || wsItem.isActiveHere || wsItem.isActiveOther)

                            opacity: showNumber ? 1 : 0
                            scale: showNumber ? 1 : 0.5

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Item {
                            anchors.fill: parent
                            z: 3

                            property bool showIcon: wsItem.hasWindows
                            opacity: showIcon ? 1 : 0
                            scale: showIcon ? 1 : 0.5

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }

                            ClippingRectangle {
                                id: iconClip
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                radius: 8
                                color: "transparent"

                                Image {
                                    id: appIcon
                                    anchors.fill: parent
                                    source: wsItem.iconPath
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    antialiasing: true
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: wsItem.clientAppId !== "" ? wsItem.clientAppId.charAt(0).toUpperCase() : ""
                                color: wsItem.isActiveHere ? Colors.md3.on_primary : Colors.md3.on_surface
                                font.pixelSize: 12
                                font.bold: true
                                visible: appIcon.status === Image.Error || appIcon.status === Image.Null
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("workspace " + wsItem.wsId)
                    }
                }
            }
        }
    }
}
