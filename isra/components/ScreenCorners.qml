import QtQuick
import qs.services
import qs.style

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

    readonly property bool masked: Config.screenCorners && !isFullscreen && !GameModeService.active
    property real maskProgress: masked ? 0 : -1
    Behavior on maskProgress {
        NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
    }

    Repeater {
        model: 4
        CornerBlock {
            required property int index
            type: index
            cornerRadius: root.cornerRadius
            maskProgress: root.maskProgress
            anchors.top: index < 2 ? parent.top : undefined
            anchors.bottom: index < 2 ? undefined : parent.bottom
            anchors.left: (index % 2 === 0) ? parent.left : undefined
            anchors.right: (index % 2 === 0) ? undefined : parent.right
        }
    }
}
