pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style
import qs.services

Item {
    id: root

    property int cellSize: 32

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Rectangle {
        id: pill
        anchors.fill: parent
        implicitWidth: root.cellSize
        implicitHeight: root.cellSize
        radius: width / 2
        property bool dragHighlight: false
        color: {
            if (dragHighlight)
                return Colors.md3.primary_container;
            if (Config.bar.transparentPills) {
                Qt.alpha(Colors.md3.secondary_container, 0)
            } else {
                Qt.alpha(Colors.md3.surface_container_high, 0.8)
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Text {
            anchors.centerIn: parent
            text: "✦"
            font.pixelSize: 22
            color: Colors.md3.primary
        }

        Rectangle {
            id: nudgeOverlay
            anchors.fill: parent
            radius: parent.radius
            color: Colors.md3.primary
            opacity: 0
        }

        SequentialAnimation {
            id: nudgeAnim
            loops: 2
            NumberAnimation {
                target: nudgeOverlay
                property: "opacity"
                to: 0.55
                duration: 180
            }
            NumberAnimation {
                target: nudgeOverlay
                property: "opacity"
                to: 0
                duration: 180
            }
        }

        Connections {
            target: AiAssistantService
            function onResponseFinished() {
                nudgeAnim.restart();
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            cursorShape: Qt.PointingHandCursor
            onTapped: toggleProc.running = true
        }

        DropArea {
            id: imageDropArea
            anchors.fill: parent
            keys: ["text/uri-list"]
            onEntered: pill.dragHighlight = true
            onExited: pill.dragHighlight = false
            onDropped: drop => {
                pill.dragHighlight = false;
                if (!drop.urls || drop.urls.length === 0)
                    return;
                for (const url of drop.urls)
                    AiAssistantService.attachFileFromUrl(url);
                AiAssistantService.open();
            }
        }
    }

    Process {
        id: toggleProc
        command: ["qs", "-c", "isra", "ipc", "call", "aiassistant", "toggle"]
    }
}
