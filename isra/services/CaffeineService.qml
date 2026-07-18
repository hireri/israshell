pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    property bool active: false

    LazyLoader {
        active: true

        PanelWindow {
            id: inhibitorWindow

            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            WlrLayershell.exclusiveZone: -1
            exclusionMode: ExclusionMode.Ignore
            visible: false

            IdleInhibitor {
                enabled: root.active
                window: inhibitorWindow
            }
        }
    }

    function toggle() {
        root.active = !root.active;
    }
}
