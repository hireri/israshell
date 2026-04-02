import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property int cornerRadius: 26
    property string cornerColor: "black"

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

            property var monitor: Hyprland.monitorFor(screen)
            property bool isFullscreen: {
                if (!monitor)
                    return false;

                let activeWs = Hyprland.workspaces.values.find(ws => ws.monitor && ws.monitor.name === monitor.name && ws.active);

                if (!activeWs)
                    return false;

                return activeWs.toplevels.values.some(top => top.wayland && top.wayland.fullscreen);
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
