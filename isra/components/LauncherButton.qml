pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick.Effects
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    property int cellSize: 32
    property int glyphSize: 18
    property bool showBackground: true

    readonly property bool _open: PanelService.current?.isLauncher === true

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Rectangle {
        id: pill
        anchors.fill: parent
        implicitWidth: root.cellSize
        implicitHeight: root.cellSize
        radius: width / 2
        color: {
            if (!root.showBackground) {
                Qt.alpha(Colors.md3.secondary_container, 0)
            } else if (root._open) {
                Colors.md3.secondary_container
            } else if (Config.bar.transparentPills) {
                Qt.alpha(Colors.md3.secondary_container, 0)
            } else {
                Qt.alpha(Colors.md3.surface_container_high, 0.8)
            }
        }

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: Config.genericLauncherIcon
            name: "action-key"
            filled: root._open
            iconSize: root.glyphSize
            color: Colors.md3.primary
        }

        IconImage {
            id: icon
            anchors.centerIn: parent
            implicitSize: root.glyphSize
            source: Quickshell.iconPath(SystemInfo.logo, "distributor-logo-linux")
            visible: false
            asynchronous: true
        }

        MultiEffect {
            anchors.fill: icon
            source: icon
            visible: !Config.genericLauncherIcon
            brightness: 0.4
            colorization: 1.0
            colorizationColor: Colors.md3.primary
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            cursorShape: Qt.PointingHandCursor
            onTapped: launcherToggleProc.running = true
        }
    }

    Process {
        id: launcherToggleProc
        command: ["qs", "-c", "isra", "ipc", "call", "launcher", "toggle"]
    }
}
