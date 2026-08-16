pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    required property var panelWindow

    implicitWidth: clockRoot.implicitWidth
    implicitHeight: clockRoot.implicitHeight

    property bool isOpen: false
    property bool _calVisible: false

    function close(): void {
        isOpen = false;
    }

    onIsOpenChanged: {
        if (isOpen) {
            _calVisible = true;
            PanelService.opened(root, root.panelWindow.screen);
        } else {
            calCloseTimer.restart();
            PanelService.closed(root);
        }
    }

    Timer {
        id: calCloseTimer
        interval: 380
        onTriggered: if (!root.isOpen)
            root._calVisible = false
    }

    TransformWatcher {
        id: pillTransform
        a: root
        b: root.panelWindow.contentItem
    }

    Rectangle {
        id: clockRoot
        anchors.fill: parent
        color: {
            if (root.isOpen) {
                Colors.md3.secondary_container
            } else if (Config.bar.transparentPills) {
                Qt.alpha(Colors.md3.secondary_container, 0)
            } else { 
                Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
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

            readonly property bool fallbackToTime: !Config.showBarWeather && !Config.bar.showClock && !Config.bar.showDate

            Row {
                id: weatherGlance
                spacing: 4

                visible: Config.showBarWeather && LocaleService.weatherTemp !== "—"
                anchors.verticalCenter: parent.verticalCenter

                MaterialIcon {
                    visible: !Config.weather?.coloredIcons
                    name: LocaleService.weatherIconName
                    iconSize: 14
                    color: LocaleService.weatherIconColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                WeatherIcon {
                    visible: Config.weather?.coloredIcons ?? false
                    code: LocaleService.weatherCode
                    isDay: LocaleService.weatherIsDay
                    iconSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: LocaleService.weatherTemp
                    color: Colors.md3.on_surface
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                    renderType: Text.NativeRendering
                }
            }

            Text {
                text: "•"
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
                opacity: 0.5
                visible: weatherGlance.visible && (clockTime.visible || clockDate.visible)
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }

            Text {
                id: clockTime
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.features: {
                    "tnum": 1
                }
                text: LocaleService.barTimeText
                visible: (Config.bar.showClock || row.fallbackToTime) && text !== ""
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }

            Text {
                text: "•"
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
                opacity: 0.5
                visible: clockTime.visible && clockDate.visible
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
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
                visible: Config.bar.showDate && !row.fallbackToTime && text !== ""
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
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

    LazyLoader {
        id: calLoader
        active: root._calVisible

        Variants {
            id: calVariants
            model: Quickshell.screens

            PanelWindow {
                id: panel

                required property ShellScreen modelData
                screen: modelData

                readonly property bool isOwnScreen: modelData === root.panelWindow?.screen

                visible: root._calVisible

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                exclusionMode: ExclusionMode.Ignore

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                WlrLayershell.namespace: "quickshell:clockOverlay"

                readonly property bool blurEnabled: panel.isOwnScreen && Config.blurAllowed(panel.visible)
                BackgroundEffect.blurRegion: blurEnabled ? clockBlurRegion : null

                Region {
                    id: clockBlurRegion
                    item: calContent.cardItem
                }

                color: "transparent"

                Item {
                    id: keyHandler
                    anchors.fill: parent
                    focus: true

                    Component.onCompleted: forceActiveFocus()

                    Keys.onEscapePressed: event => {
                        event.accepted = true;
                        root.isOpen = false;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.isOpen = false
                }

                Item {
                    id: wrapper
                    visible: panel.isOwnScreen
                    width: calContent.implicitWidth
                    height: calContent.implicitHeight

                    readonly property real screenEdgeMargin: 12

                    anchors {
                        top: Config.bar.position === 0 ? parent.top : undefined
                        bottom: Config.bar.position === 1 ? parent.bottom : undefined
                        topMargin: Config.bar.position === 0 ? root.panelWindow.implicitHeight + 8 : 0
                        bottomMargin: Config.bar.position === 1 ? root.panelWindow.implicitHeight + 8 : 0
                    }

                    function _clamp(value, min, max) {
                        return max >= min ? Math.max(min, Math.min(max, value)) : min;
                    }

                    function _screenWidth() {
                        return (root.panelWindow.screen && root.panelWindow.screen.width > 0) ? root.panelWindow.screen.width : panel.width;
                    }

                    x: {
                        pillTransform.transform;
                        const pillCenterLocal = root.width / 2;
                        const mappedPoint = root.mapToItem(root.panelWindow.contentItem, pillCenterLocal, 0);
                        const idealX = mappedPoint.x - (calContent.implicitWidth / 2);

                        const screenWidth = wrapper._screenWidth();
                        return Math.round(wrapper._clamp(idealX, screenEdgeMargin, screenWidth - calContent.implicitWidth - screenEdgeMargin));
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {}
                    }

                    ClockCalendar {
                        id: calContent
                        anchors.fill: parent
                        isOpen: root.isOpen
                        edgeMargin: root.panelWindow.implicitHeight

                        onCalendarRequested: root.isOpen = false
                        onSettingsRequested: root.isOpen = false
                    }
                }
            }
        }
    }
}
