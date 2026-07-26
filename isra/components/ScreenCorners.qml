import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

Scope {
    id: root

    property int cornerRadius: 26
    property string cornerColor: !GameModeService.active ? "black" : "transparent"

    component CornerBlock: Item {
        id: block
        property int type: 0
        width: root.cornerRadius
        height: root.cornerRadius
        clip: true

        Rectangle {
            width: root.cornerRadius * 4
            height: root.cornerRadius * 4
            radius: root.cornerRadius * 2
            color: "transparent"

            border.width: root.cornerRadius
            border.color: root.cornerColor

            x: (block.type === 1 || block.type === 3) ? -root.cornerRadius * 2 : -root.cornerRadius
            y: (block.type === 2 || block.type === 3) ? -root.cornerRadius * 2 : -root.cornerRadius
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: cornerWindow
            required property var modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.namespace: "quickshell:screenCorners"
            WlrLayershell.layer: WlrLayer.Overlay

            mask: Region {}

            property var monitor: CompositorService.monitorFor(screen)
            property string monitorName: monitor.name

            property bool isFullscreen: {
                if (monitorName === "")
                    return false;

                const activeWs = CompositorService.workspaces.find(ws => ws.monitor === monitorName && ws.active);
                if (!activeWs)
                    return false;

                return CompositorService.windows.some(w => w.workspace === activeWs.id && w.fullscreen);
            }

            visible: !isFullscreen

            CornerBlock {
                type: 0
                anchors.top: parent.top
                anchors.left: parent.left
            }
            CornerBlock {
                type: 1
                anchors.top: parent.top
                anchors.right: parent.right
            }
            CornerBlock {
                type: 2
                anchors.bottom: parent.bottom
                anchors.left: parent.left
            }
            CornerBlock {
                type: 3
                anchors.bottom: parent.bottom
                anchors.right: parent.right
            }
        }
    }
}
