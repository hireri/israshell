pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.style

PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "quickshell:neko-overlay"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }

    mask: Region {}

    Neko {
        modelData: root.modelData
    }
}
