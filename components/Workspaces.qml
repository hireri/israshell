import Quickshell
import Quickshell.Hyprland
import QtQuick

import qs.style

Rectangle {
    required property var panelWindow

    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
    radius: 12
    width: workspacesContent.implicitWidth + 28
    height: 32

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor

        onWheel: wheel => {
            const monitor = Hyprland.monitorFor(panelWindow.modelData);
            if (!monitor)
                return;

            const currentWs = Hyprland.workspaces.values.find(w => w.active && w.monitor === monitor);
            if (!currentWs)
                return;

            const currentId = currentWs.id;
            const direction = wheel.angleDelta.y > 0 ? -1 : 1;
            const otherMonitorWorkspaces = new Set(Hyprland.workspaces.values.filter(w => w.monitor && w.monitor !== monitor).map(w => w.id));

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

    Row {
        id: workspacesContent
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: 10
            Item {
                width: 12
                height: 30
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: 12
                    height: 12
                    radius: 5
                    anchors.centerIn: parent

                    Behavior on color {
                        ColorAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }

                    color: {
                        const wsId = index + 1;
                        const monitor = Hyprland.monitorFor(panelWindow.modelData);
                        if (!monitor)
                            return Colors.md3.outline_variant;

                        const ws = Hyprland.workspaces.values.find(w => w.id === wsId);
                        if (ws && ws.active && ws.monitor === monitor)
                            return Colors.md3.primary;

                        return Hyprland.workspaces.values.some(w => w.id === wsId) ? Colors.md3.outline : Colors.md3.outline_variant;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + (index + 1))
                }
            }
        }
    }
}
