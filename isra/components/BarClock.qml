import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.style
import qs.services

Item {
    id: root

    required property var panelWindow

    implicitWidth: clockRoot.implicitWidth
    implicitHeight: clockRoot.implicitHeight

    property bool isOpen: false
    property bool _calVisible: false

    onIsOpenChanged: {
        if (isOpen) {
            _calVisible = true;
        } else {
            calCloseTimer.restart();
        }
    }

    Timer {
        id: calCloseTimer
        interval: 380
        onTriggered: if (!root.isOpen)
            root._calVisible = false
    }

    Rectangle {
        id: clockRoot
        anchors.fill: parent
        color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
        radius: 18
        implicitWidth: row.implicitWidth + 32
        implicitHeight: row.implicitHeight + 14

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6

            Text {
                id: clockTime
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.features: {
                    "tnum": 1
                }
                text: LocaleService.barTimeText
            }

            Text {
                text: "•"
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
                opacity: 0.5
            }

            Text {
                id: clockDate
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.features: {
                    "tnum": 1
                }
                text: LocaleService.barDateText
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            cursorShape: Qt.PointingHandCursor
            onTapped: root.isOpen = !root.isOpen
        }
    }

    HyprlandFocusGrab {
        windows: [calLoader.item]
        active: root.isOpen && calLoader.active
        onCleared: root.isOpen = false
    }

    LazyLoader {
        id: calLoader
        active: root._calVisible

        PopupWindow {
            id: popup
            visible: root._calVisible
            mask: Region {
                item: root.isOpen ? calContent : null
            }

            anchor.window: root.panelWindow
            anchor.rect: Qt.rect(Math.round((root.panelWindow.width - calContent.implicitWidth) / 2), 0, calContent.implicitWidth, root.panelWindow.height)
            anchor.edges: (Config.barPosition === 1 ? Edges.Top : Edges.Bottom) | Edges.Left
            anchor.gravity: (Config.barPosition === 1 ? Edges.Top : Edges.Bottom) | Edges.Right

            implicitWidth: calContent.implicitWidth
            implicitHeight: calContent.implicitHeight + 8
            color: "transparent"

            onVisibleChanged: {
                if (visible)
                    calContent.init();
            }

            ClockCalendar {
                id: calContent
                anchors.fill: parent
                isOpen: root.isOpen
            }
        }
    }
}
