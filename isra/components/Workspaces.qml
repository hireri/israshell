import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import QtQuick

import qs.style
import qs.services

Rectangle {
    id: root
    required property var panelWindow

    readonly property bool isOpen: false

    color: {
        if (root.isOpen) {
            Colors.md3.secondary_container
        } else if (Config.bar.transparentPills) {
            Qt.alpha(Colors.md3.secondary_container, 0)
        } else { 
            Qt.alpha(Colors.md3.surface_container_high, 0.8)
        }
    }
    radius: 18
    implicitWidth: workspacesContent.implicitWidth + 10
    height: 32

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    readonly property bool isNiri: SystemInfo.compositor === "niri" || CompositorService.backendName === "niri"
    readonly property string currentMonitorName: panelWindow.modelData?.name ?? ""
    property var currentMonitor: CompositorService.monitors.find(m => m.name === currentMonitorName)

    readonly property var niriWorkspaces: {
        if (!isNiri) return [];
        return CompositorService.workspaces.filter(w => w.monitor === currentMonitorName);
    }

    property int activeWorkspaceId: {
        if (currentMonitorName === "")
            return -1;
        const ws = CompositorService.workspaces.find(w => w.active && w.monitor === currentMonitorName);
        if (ws)
            return ws.id;
        return root.currentMonitor?.activeWorkspaceId ?? 1;
    }

    property int activeIndex: Math.max(0, Math.min(activeWorkspaceId - 1, 9))

    property var visibleIds: {
        if (isNiri) return [];
        if (!Config.workspaces.compact) {
            return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        }
        const ids = [];
        for (let id = 1; id <= 10; id++) {
            const wsObj = CompositorService.workspaces.find(w => w.id === id);
            const hasWindows = CompositorService.windows.find(w => w.workspace === id) !== undefined;
            const isActiveHere = root.activeWorkspaceId === id;
            const isActiveOther = wsObj !== undefined && wsObj.active && wsObj.monitor !== root.currentMonitorName;
            const takenByMonitor = wsObj !== undefined && wsObj.monitor !== "";

            if (hasWindows || takenByMonitor || isActiveHere || isActiveOther)
                ids.push(id);
        }
        return ids;
    }

    property int activeVisualIndex: {
        if (isNiri) {
            if (niriWorkspaces.length === 0) return 0;
            const idx = niriWorkspaces.findIndex(w => w.id === activeWorkspaceId || w.active);
            return Math.max(0, idx);
        } else {
            return Math.max(0, visibleIds.findIndex(id => Number(id) === Number(activeWorkspaceId)));
        }
    }

    property bool hasActiveWorkspace: activeWorkspaceId > 0 || (isNiri && niriWorkspaces.length > 0)

    readonly property int repeaterModel: {
        if (isNiri) {
            return Math.max(1, niriWorkspaces.length);
        }
        return 10;
    }

    HoverHandler {
        id: rootHover
    }

    property bool isHovered: rootHover.hovered || mainMouseArea.containsMouse

    function getAppId(w) {
        if (w === undefined || w.address === "")
            return "";
        return w.appId;
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

    function getWorkspaceLabel(wsItem) {
        if (root.isNiri && wsItem.wsObj && wsItem.wsObj.name && isNaN(Number(wsItem.wsObj.name))) {
            return wsItem.wsObj.name;
        }
        const id = wsItem.displayIndex;
        const style = Config.workspaces.style || 0;
        if (style === 1) {
            const roman = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"];
            return roman[(id - 1) % 10] || id.toString();
        } else if (style === 2) {
            const kanji = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"];
            return kanji[(id - 1) % 10] || id.toString();
        }
        return id.toString();
    }

    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true

        onWheel: wheel => {
            if (root.currentMonitorName === "")
                return;

            const direction = wheel.angleDelta.y > 0 ? -1 : 1;

            if (root.isNiri) {
                const list = root.niriWorkspaces;
                if (list.length === 0) return;
                let currentIdx = list.findIndex(w => w.id === root.activeWorkspaceId || w.active);
                if (currentIdx === -1) currentIdx = 0;
                let targetIdx = Math.max(0, Math.min(list.length - 1, currentIdx + direction));
                if (targetIdx !== currentIdx) {
                    const targetWs = list[targetIdx];
                    let ref = targetIdx + 1; 
                    if (targetWs && targetWs.name && isNaN(Number(targetWs.name))) {
                        ref = targetWs.name;
                    }
                    CompositorService.focusWorkspace(ref, root.currentMonitorName);
                }
                return;
            }

            const currentId = root.activeWorkspaceId;
            const otherMonitorWorkspaces = new Set(CompositorService.workspaces.filter(w => w.monitor !== "" && w.monitor !== root.currentMonitorName).map(w => w.id));

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
                CompositorService.focusWorkspace(target, "");
        }
    }

    Item {
        id: workspacesContent
        anchors.centerIn: parent
        implicitWidth: Math.max(0, row.implicitWidth - 8)
        height: 24

        Rectangle {
            id: activeIndicator
            width: 24
            height: 24
            radius: 12
            color: Colors.md3.primary
            visible: root.hasActiveWorkspace

            x: root.activeVisualIndex * 32
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
            spacing: 0

            Repeater {
                model: root.repeaterModel

                Item {
                    id: wsItem
                    property int itemIndex: index
                    property int displayIndex: index + 1

                    property var wsObj: {
                        if (root.isNiri) {
                            return root.niriWorkspaces[index] ?? null;
                        }
                        return CompositorService.workspaces.find(w => w.id === displayIndex);
                    }

                    property var wsId: {
                        if (root.isNiri) {
                            return wsObj ? wsObj.id : displayIndex;
                        }
                        return displayIndex;
                    }

                    property var wsRef: {
                        if (root.isNiri) {
                            if (wsObj && wsObj.name && isNaN(Number(wsObj.name))) {
                                return wsObj.name;
                            }
                            return displayIndex;
                        }
                        return displayIndex;
                    }

                    property bool isActiveHere: {
                        if (root.isNiri) {
                            return wsObj ? (wsObj.id === root.activeWorkspaceId || wsObj.active) : (index === 0);
                        }
                        return root.activeWorkspaceId === wsId;
                    }

                    property bool isActiveOther: {
                        if (root.isNiri) return false;
                        return wsObj !== undefined && wsObj.active && wsObj.monitor !== root.currentMonitorName;
                    }

                    property bool takenByMonitor: {
                        if (root.isNiri) return false;
                        return wsObj !== undefined && wsObj.monitor !== "";
                    }

                    property var firstWindow: CompositorService.windows.find(w => w.workspace === wsId)
                    property bool hasWindows: firstWindow !== undefined

                    property bool isVisible: {
                        if (root.isNiri) return true;
                        return !Config.workspaces.compact || hasWindows || takenByMonitor || isActiveHere || isActiveOther;
                    }

                    property string clientAppId: root.getAppId(firstWindow)
                    property string iconPath: root.getIconSource(clientAppId)

                    property bool showIcon: Config.workspaces.useIcons && hasWindows

                    property bool showNumber: {
                        if (showIcon) return false;
                        if (root.isNiri) return true;
                        return root.isHovered || isActiveHere || isActiveOther || hasWindows;
                    }

                    property bool showDot: {
                        if (root.isNiri) return false;
                        return !showIcon && !root.isHovered && !isActiveHere && !isActiveOther && !hasWindows;
                    }

                    width: isVisible ? 32 : 0
                    height: 24
                    clip: true

                    Behavior on width {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    Item {
                        id: pillContent
                        width: 24
                        height: 24
                        anchors.left: parent.left

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

                                opacity: wsItem.showDot ? 1 : 0
                                scale: wsItem.showDot ? 1 : 0.5

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
                                text: root.getWorkspaceLabel(wsItem)

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

                                opacity: wsItem.showNumber ? 1 : 0
                                scale: wsItem.showNumber ? 1 : 0.5

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

                                property bool showIcon: wsItem.showIcon
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
                                        asynchronous: true
                                        cache: true
                                        sourceSize: Qt.size(24, 24)
                                        visible: !Config.tintIcons
                                    }

                                    Loader {
                                        active: Config.tintIcons
                                        anchors.fill: appIcon
                                        sourceComponent: Colorize {
                                            source: appIcon
                                            hue: Qt.color(Colors.md3.on_surface).hslHue
                                            saturation: Qt.color(Colors.md3.on_surface).hslSaturation
                                            lightness: 0.0
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.isNiri) {
                                    CompositorService.focusWorkspace(wsItem.wsRef, root.currentMonitorName);
                                } else {
                                    CompositorService.focusWorkspace(wsItem.wsId, "");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}