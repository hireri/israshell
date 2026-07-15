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
        color: {
            if (root.isOpen) {
                Colors.md3.secondary_container
            } else if (Config.bar.transparentPills) {
                Config.bar.transparency ? Qt.alpha(Colors.md3.secondary_container, 0) : Colors.md3.surface_container
            } else { 
                Config.bar.transparency ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
            }
        }
        radius: 18
        implicitWidth: row.implicitWidth + 32
        implicitHeight: row.implicitHeight + 14

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
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

            // 1. Anchor directly to the entire bar window to fix the vertical height
            anchor.window: root.panelWindow

            anchor.edges: (Config.bar.position === 1 ? Edges.Top : Edges.Bottom) | Edges.Left
            anchor.gravity: (Config.bar.position === 1 ? Edges.Top : Edges.Bottom) | Edges.Right

            // 2. Map the coordinate of the pill to the bar window to center it accurately
            anchor.rect: {
                // Map the center-point of the pill to the panelWindow coordinate system
                const pillCenterLocal = root.width / 2;
                const mappedPoint = root.mapToItem(root.panelWindow.contentItem, pillCenterLocal, 0);
                
                // Calculate X centered relative to the mapped point
                const popupX = Math.round(mappedPoint.x - (calContent.implicitWidth / 2));
                
                return Qt.rect(
                    popupX, 
                    0, 
                    calContent.implicitWidth, 
                    root.panelWindow.height
                )
            }

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
                
                onCalendarRequested: root.isOpen = false
                onSettingsRequested: root.isOpen = false
            }
        }
    }
}
