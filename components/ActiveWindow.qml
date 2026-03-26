import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

import qs.style

Rectangle {
    color: "transparent"
    radius: 12
    implicitWidth: leftContent.implicitWidth + 20
    height: 32

    Row {
        id: leftContent
        anchors.centerIn: parent
        spacing: 8

        IconImage {
            implicitSize: 28
            anchors.verticalCenter: parent.verticalCenter
            source: {
                const active = Hyprland.toplevels.values.find(t => t.activated);
                return active?.wayland ? "image://icon/" + active.wayland.appId : "";
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: {
                    const active = Hyprland.toplevels.values.find(t => t.activated);
                    return active?.wayland ? active.wayland.appId : "";
                }
                color: Colors.md3.on_surface_variant
                font.pixelSize: 10
                font.family: Config.fontFamily
            }

            Text {
                text: {
                    const active = Hyprland.toplevels.values.find(t => t.activated);
                    return active ? active.title : "";
                }
                color: Colors.md3.on_surface
                font.pixelSize: 12
                font.family: Config.fontFamily
            }
        }
    }
}
