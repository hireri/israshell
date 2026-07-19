pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick.Effects
import qs.style
import qs.services

Item {
    id: root

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Rectangle {
        id: pill
        anchors.fill: parent
        implicitWidth: 32
        implicitHeight: 32
        radius: width / 2
        color: {
            if (Config.bar.transparentPills) {
                Config.bar.transparency ? Qt.alpha(Colors.md3.secondary_container, 0) : Colors.md3.surface_container
            } else {
                Config.bar.transparency ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
            }
        }

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        IconImage {
            id: icon
            anchors.centerIn: parent
            implicitSize: 18
            source: Quickshell.iconPath(SystemInfo.logo, "distributor-logo-linux")
            visible: false
            asynchronous: true
        }

        MultiEffect {
            anchors.fill: icon
            source: icon
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
