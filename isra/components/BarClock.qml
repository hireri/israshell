pragma ComponentBehavior: Bound
import QtQuick
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    required property var panelWindow
    property var controllerRegistry: null

    readonly property string panelType: "calendar"

    implicitWidth: clockRoot.implicitWidth
    implicitHeight: clockRoot.implicitHeight

    property bool isOpen: false

    function close(): void {
        isOpen = false;
    }

    onIsOpenChanged: {
        if (isOpen) {
            PanelService.opened(root, root.panelWindow.screen);
        } else {
            PanelService.closed(root);
        }
    }

    Component.onCompleted: {
        if (root.controllerRegistry)
            root.controllerRegistry[root.panelType] = root;
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
}
