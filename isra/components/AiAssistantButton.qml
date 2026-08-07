pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Shapes
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

        Shape {
            id: geminiLogo
            anchors.centerIn: parent
            width: parent.width * 0.5
            height: width
            antialiasing: true
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                strokeWidth: 0
                fillGradient: LinearGradient {
                    x1: 0
                    y1: 0
                    x2: geminiLogo.width
                    y2: geminiLogo.height
                    GradientStop {
                        position: 0.0
                        color: ColorUtils.hueShift(Colors.md3.primary, -120)
                    }
                    GradientStop {
                        position: 0.5
                        color: Colors.md3.primary
                    }
                    GradientStop {
                        position: 1.0
                        color: ColorUtils.hueShift(Colors.md3.primary, 120)
                    }
                }
                scale: Qt.size(geminiLogo.width / 16, geminiLogo.height / 16)

                PathSvg {
                    path: "M8 0C8 4.418 4.418 8 0 8c4.418 0 8 3.582 8 8 0-4.418 3.582-8 8-8-4.418 0-8-3.582-8-8Z"
                }
            }
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
