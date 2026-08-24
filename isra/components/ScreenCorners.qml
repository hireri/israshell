import QtQuick
import qs.services

Item {
    id: root

    property int cornerRadius: 26
    property var screen: null

    anchors.fill: parent

    readonly property string monitorName: CompositorService.monitorFor(root.screen)?.name ?? ""

    readonly property bool isFullscreen: {
        if (monitorName === "")
            return false;
        const activeWs = CompositorService.workspaces.find(ws => ws.monitor === monitorName && ws.active);
        if (!activeWs)
            return false;
        return CompositorService.windows.some(w => w.workspace === activeWs.id && w.fullscreen);
    }

    visible: !isFullscreen && !GameModeService.active

    Repeater {
        model: 4
        CornerBlock {
            required property int index
            type: index
            cornerRadius: root.cornerRadius
            anchors.top: index < 2 ? parent.top : undefined
            anchors.bottom: index < 2 ? undefined : parent.bottom
            anchors.left: (index % 2 === 0) ? parent.left : undefined
            anchors.right: (index % 2 === 0) ? undefined : parent.right
        }
    }
}
