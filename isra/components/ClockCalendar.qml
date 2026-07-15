import QtQuick
import Quickshell
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    required property bool isOpen

    signal calendarRequested
    signal settingsRequested

    readonly property var shape: ({
            extraSmall: 4,
            small: 8,
            medium: 12,
            large: 16,
            extraLarge: 28,
            full: 9999
        })

    readonly property var motion: ({
            short2: 100,
            short3: 150,
            short4: 200,
            medium3: 350,
            long4: 600
        })

    readonly property var type: ({
            displayLarge: 57,
            titleLarge: 22,
            titleSmall: 14,
            headlineSmall: 24,
            bodyMedium: 14,
            bodySmall: 12
        })

    readonly property var weatherColor: ({
            sun: "#F9A825",
            cloud: Colors.md3.on_surface_variant,
            rain: "#5C8DEA",
            storm: Colors.md3.tertiary,
            snow: Colors.md3.on_surface,
            heat: Colors.md3.tertiary,
            humidity: "#5C8DEA",
            air: Colors.md3.secondary
        })

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    function getWeatherIconComponent() {
        const c = parseInt(LocaleService.weatherCode);
        if (c === 113)
            return sunnyComponent;
        if (c === 116)
            return partlyCloudyComponent;
        if (c === 119 || c === 122 || c === 143)
            return cloudyComponent;
        if ([176, 263, 266, 293, 296, 299, 302, 305, 308, 311, 314, 353, 356, 359].includes(c))
            return rainComponent;
        if ([200, 386, 389].includes(c))
            return stormComponent;
        if ([227, 230, 320, 323, 326, 329, 332, 335, 338, 368, 371].includes(c))
            return snowComponent;
        return partlyCloudyComponent;
    }

    Component {
        id: sunnyComponent
        WbSunnyIcon {
            iconSize: 36
            color: root.weatherColor.sun
        }
    }
    Component {
        id: partlyCloudyComponent
        PartlyCloudyDayIcon {
            iconSize: 36
            color: Colors.md3.primary
        }
    }
    Component {
        id: cloudyComponent
        CloudyIcon {
            iconSize: 36
            color: root.weatherColor.cloud
        }
    }
    Component {
        id: rainComponent
        RainyIcon {
            iconSize: 36
            color: root.weatherColor.rain
        }
    }
    Component {
        id: stormComponent
        ThunderstormIcon {
            iconSize: 36
            color: root.weatherColor.storm
        }
    }
    Component {
        id: snowComponent
        SnowyIcon {
            iconSize: 36
            color: root.weatherColor.snow
        }
    }

    Rectangle {
        id: card
        property bool _ready: false
        Component.onCompleted: Qt.callLater(() => _ready = true)

        y: {
            const open = _ready && root.isOpen;
            if (Config.bar.position === 0)
                return open ? 8 : -(height + 8);
            return open ? 0 : height + 8;
        }
        Behavior on y {
            NumberAnimation {
                duration: root.motion.medium3
                easing.type: Easing.OutExpo
            }
        }

        implicitWidth: 300
        implicitHeight: content.implicitHeight + 32

        color: Colors.md3.surface_container_low
        radius: root.shape.large
        border.width: 1
        border.color: Colors.md3.outline_variant
        layer.enabled: true

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            Column {
                width: parent.width
                spacing: 0

                Row {
                    spacing: 6

                    Text {
                        id: timeText
                        text: LocaleService.liveTime
                        color: Colors.md3.on_surface
                        font.family: "Google Sans Display"
                        font.pixelSize: root.type.displayLarge
                        font.weight: Font.Light
                        font.features: ({
                                "tnum": 1
                            })
                        Behavior on color {
                            ColorAnimation {
                                duration: root.motion.short4
                            }
                        }
                    }

                    Column {
                        anchors.verticalCenter: timeText.verticalCenter
                        spacing: 0

                        Text {
                            opacity: LocaleService.liveAmPm !== "" ? 1.0 : 0.0
                            text: LocaleService.liveAmPm !== "" ? LocaleService.liveAmPm.trim() : "am"
                            color: Colors.md3.on_surface_variant
                            font.family: "Google Sans Display"
                            font.pixelSize: root.type.titleSmall
                            font.weight: Font.Light
                            height: timeText.height / 2
                            verticalAlignment: Text.AlignBottom
                            Behavior on color {
                                ColorAnimation {
                                    duration: root.motion.short4
                                }
                            }
                        }

                        Text {
                            text: ":" + LocaleService.liveSecs
                            color: Colors.md3.primary
                            font.family: "Google Sans Display"
                            font.pixelSize: root.type.titleSmall
                            font.weight: Font.Light
                            font.features: ({
                                    "tnum": 1
                                })
                            height: timeText.height / 2
                            verticalAlignment: Text.AlignTop
                            Behavior on color {
                                ColorAnimation {
                                    duration: root.motion.short4
                                }
                            }
                        }
                    }
                }

                Text {
                    text: LocaleService.liveDayName
                    color: Colors.md3.primary
                    font.family: Config.fontFamily
                    font.pixelSize: root.type.titleSmall
                    font.weight: Font.Medium
                    topPadding: 4
                    Behavior on color {
                        ColorAnimation {
                            duration: root.motion.short4
                        }
                    }
                }

                Text {
                    text: LocaleService.liveFullDate
                    color: Colors.md3.on_surface_variant
                    font.family: Config.fontFamily
                    font.pixelSize: root.type.bodyMedium
                    topPadding: 2
                    Behavior on color {
                        ColorAnimation {
                            duration: root.motion.short4
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Colors.md3.outline_variant
                Behavior on color {
                    ColorAnimation {
                        duration: root.motion.short4
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 10

                Row {
                    width: parent.width
                    spacing: 14

                    Loader {
                        sourceComponent: root.getWeatherIconComponent()
                        anchors.verticalCenter: parent.verticalCenter
                        Connections {
                            target: LocaleService
                            function onWeatherCodeChanged() {
                                sourceComponent = root.getWeatherIconComponent();
                            }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Row {
                            spacing: 8

                            Text {
                                id: tempLabel
                                text: LocaleService.weatherTemp
                                font.pixelSize: root.type.headlineSmall
                                color: Colors.md3.on_surface
                                font.family: Config.fontFamily
                                Behavior on color {
                                    ColorAnimation {
                                        duration: root.motion.short4
                                    }
                                }
                            }

                            Text {
                                text: LocaleService.weatherHigh + " / " + LocaleService.weatherLow
                                font.pixelSize: root.type.bodyMedium
                                font.weight: Font.Medium
                                color: Colors.md3.on_surface_variant
                                font.family: Config.fontFamily
                                anchors.baseline: tempLabel.baseline
                                Behavior on color {
                                    ColorAnimation {
                                        duration: root.motion.short4
                                    }
                                }
                            }
                        }

                        Text {
                            text: LocaleService.weatherDesc
                            font.pixelSize: root.type.bodySmall
                            font.weight: Font.Medium
                            color: Colors.md3.on_surface_variant
                            font.family: Config.fontFamily
                            Behavior on color {
                                ColorAnimation {
                                    duration: root.motion.short4
                                }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 16

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        HeatIcon {
                            iconSize: 14
                            color: root.weatherColor.heat
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: LocaleService.weatherUvi + " UVI"
                            color: Colors.md3.on_surface_variant
                            font.family: Config.fontFamily
                            font.pixelSize: root.type.bodySmall
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color {
                                ColorAnimation {
                                    duration: root.motion.short4
                                }
                            }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        WaterDropIcon {
                            iconSize: 14
                            color: root.weatherColor.humidity
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: LocaleService.weatherHumid
                            color: Colors.md3.on_surface_variant
                            font.family: Config.fontFamily
                            font.pixelSize: root.type.bodySmall
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color {
                                ColorAnimation {
                                    duration: root.motion.short4
                                }
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        AirIcon {
                            iconSize: 14
                            color: root.weatherColor.air
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: LocaleService.weatherAqi + " AQI"
                            color: Colors.md3.on_surface_variant
                            font.family: Config.fontFamily
                            font.pixelSize: root.type.bodySmall
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color {
                                ColorAnimation {
                                    duration: root.motion.short4
                                }
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    id: calendarBtn
                    width: (parent.width - 8) / 2
                    height: 36
                    radius: root.shape.full
                    color: calendarMA.containsMouse ? Colors.md3.secondary_container : Colors.md3.surface_container_highest
                    Behavior on color {
                        ColorAnimation {
                            duration: root.motion.short2
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        CalendarMonthIcon {
                            iconSize: 16
                            color: calendarMA.containsMouse ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Calendar"
                            font.family: Config.fontFamily
                            font.pixelSize: root.type.bodySmall
                            font.weight: Font.Medium
                            color: calendarMA.containsMouse ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: calendarMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.calendarRequested()
                            Quickshell.execDetached(["gnome-calendar"])
                        }
                    }
                }

                Rectangle {
                    id: settingsBtn
                    width: (parent.width - 8) / 2
                    height: 36
                    radius: root.shape.full
                    color: settingsMA.containsMouse ? Colors.md3.surface_container_highest : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: root.motion.short2
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        SettingsIcon {
                            iconSize: 16
                            color: Colors.md3.on_surface_variant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Settings"
                            font.family: Config.fontFamily
                            font.pixelSize: root.type.bodySmall
                            font.weight: Font.Medium
                            color: Colors.md3.on_surface_variant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: settingsMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.settingsRequested()
                            Quickshell.execDetached(["qs", "-c", "isra", "ipc", "call", "settings", "open", "locale"])
                        }
                    }
                }
            }
        }
    }
}
