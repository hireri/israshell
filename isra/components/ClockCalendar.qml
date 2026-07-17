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
            sun: Colors.md3.tertiary,
            cloud: Colors.md3.on_surface_variant,
            rain: Colors.md3.primary,
            storm: Colors.md3.error,
            snow: Colors.md3.outline,
            heat: Colors.md3.error,
            humidity: Colors.md3.secondary,
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
        MaterialIcon {
    name: "wb-sunny"
            iconSize: 36
            color: root.weatherColor.sun
        }
    }
    Component {
        id: partlyCloudyComponent
        MaterialIcon {
    name: "partly-cloudy-day"
            iconSize: 36
            color: Colors.md3.primary
        }
    }
    Component {
        id: cloudyComponent
        MaterialIcon {
    name: "cloudy"
            iconSize: 36
            color: root.weatherColor.cloud
        }
    }
    Component {
        id: rainComponent
        MaterialIcon {
    name: "rainy"
            iconSize: 36
            color: root.weatherColor.rain
        }
    }
    Component {
        id: stormComponent
        MaterialIcon {
    name: "thunderstorm"
            iconSize: 36
            color: root.weatherColor.storm
        }
    }
    Component {
        id: snowComponent
        MaterialIcon {
    name: "snowy"
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

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            Column {
                width: parent.width
                spacing: 0

                Row {
                    spacing: 8

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
                    topPadding: 4
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
                spacing: 12

                Row {
                    width: parent.width
                    spacing: 16

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
                        spacing: 4

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

                Grid {
                    id: weatherGrid
                    width: parent.width
                    columns: 3
                    spacing: 4

                    readonly property real cellWidth: (width - spacing * 2) / 3
                    readonly property real cellHeight: 26

                    Rectangle {
                        width: weatherGrid.cellWidth
                        height: weatherGrid.cellHeight
                        color: Colors.md3.surface_container_high
                        radius: root.shape.extraSmall
                        topLeftRadius: root.shape.medium

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialIcon {
    name: "heat"
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
                    }

                    Rectangle {
                        width: weatherGrid.cellWidth
                        height: weatherGrid.cellHeight
                        color: Colors.md3.surface_container_high
                        radius: root.shape.extraSmall

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialIcon {
    name: "water-drop"
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
                    }

                    Rectangle {
                        width: weatherGrid.cellWidth
                        height: weatherGrid.cellHeight
                        color: Colors.md3.surface_container_high
                        radius: root.shape.extraSmall
                        topRightRadius: root.shape.medium

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialIcon {
    name: "air"
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

                    Rectangle {
                        width: weatherGrid.cellWidth
                        height: weatherGrid.cellHeight
                        color: Colors.md3.surface_container_high
                        radius: root.shape.extraSmall
                        bottomLeftRadius: root.shape.medium

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialIcon {
    name: "thermostat"
                                iconSize: 14
                                color: Colors.md3.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Fl " + LocaleService.weatherFeelsLike
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

                    Rectangle {
                        width: weatherGrid.cellWidth
                        height: weatherGrid.cellHeight
                        color: Colors.md3.surface_container_high
                        radius: root.shape.extraSmall

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialIcon {
    name: "umbrella"
                                iconSize: 14
                                color: root.weatherColor.rain
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: LocaleService.weatherRainChance
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

                    Rectangle {
                        width: weatherGrid.cellWidth
                        height: weatherGrid.cellHeight
                        color: Colors.md3.surface_container_high
                        radius: root.shape.extraSmall
                        bottomRightRadius: root.shape.medium

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialIcon {
    name: "wb-twilight"
                                iconSize: 14
                                color: root.weatherColor.sun
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: LocaleService.weatherSunset.replace(" AM", "").replace(" PM", "")
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
            }

            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    id: calendarBtn
                    width: (parent.width - 8) / 2
                    height: 36
                    radius: root.shape.full
                    color: Colors.md3.secondary_container

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Colors.md3.on_secondary_container
                        opacity: calendarMA.containsMouse ? 0.08 : 0.0
                        Behavior on opacity {
                            NumberAnimation { duration: root.motion.short2 }
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        MaterialIcon {
    name: "calendar-month"
                            iconSize: 16
                            color: Colors.md3.on_secondary_container
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Calendar"
                            font.family: Config.fontFamily
                            font.pixelSize: root.type.bodySmall
                            font.weight: Font.Medium
                            color: Colors.md3.on_secondary_container
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
                    color: Colors.md3.surface_container_high

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Colors.md3.on_surface
                        opacity: settingsMA.containsMouse ? 0.08 : 0.0
                        Behavior on opacity {
                            NumberAnimation { duration: root.motion.short2 }
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        MaterialIcon {
    name: "settings"
                            iconSize: 16
                            color: Colors.md3.on_surface
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Settings"
                            font.family: Config.fontFamily
                            font.pixelSize: root.type.bodySmall
                            font.weight: Font.Medium
                            color: Colors.md3.on_surface
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