import QtQuick
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    required property bool isOpen
    property real edgeMargin: 0
    property var editing: null
    property bool editorOpen: false
    property bool editorLoaded: false

    readonly property var dayMap: {
        const cs = calGrid.cells;
        return CalendarService.byDay(new Date(cs[0].y, cs[0].m, cs[0].d).getTime(), new Date(cs[41].y, cs[41].m, cs[41].d + 1).getTime());
    }
    readonly property var selEvents: {
        const d = calGrid.selectedDate;
        return CalendarService.byDay(new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime(), new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1).getTime())[calGrid.selKey] ?? [];
    }
    readonly property var eventCounts: {
        const o = {};
        for (const k in dayMap)
            o[k] = dayMap[k].length;
        return o;
    }

    function openEditor(ev) {
        if (ev?.readOnly)
            return;
        editing = ev;
        editorLoaded = true;
        editorOpen = true;
    }

    function closeEditor() {
        editorOpen = false;
        root.forceActiveFocus();
    }

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

    onIsOpenChanged: {
        if (isOpen) {
            hourScroll.recenter();
            reloadTimer.restart();
        } else {
            editorOpen = false;
        }
    }

    Timer {
        id: reloadTimer
        interval: root.motion.medium3 + 50
        onTriggered: CalendarService.reload()
    }

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight
    property alias cardItem: card

    Rectangle {
        id: card
        property bool _ready: false
        Component.onCompleted: Qt.callLater(() => _ready = true)

        y: {
            const open = _ready && root.isOpen;
            if (Config.bar.position === 0)
                return open ? 0 : -(height + root.edgeMargin + 8);
            return open ? 0 : height + root.edgeMargin + 8;
        }
        Behavior on y {
            NumberAnimation {
                duration: root.motion.medium3
                easing.type: Easing.OutExpo
            }
        }

        implicitWidth: 601
        implicitHeight: Math.max(content.implicitHeight + 16 + 86, calPane.implicitHeight) + 32

        color: Qt.alpha(Colors.md3.surface_container_low, Config.blurOpacity)
        radius: root.shape.large
        border.width: 1
        border.color: Colors.md3.outline_variant

        Column {
            id: content
            x: 16
            y: 16
            width: 268
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
                        font.family: Config.fontFamily
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
                            font.family: Config.fontFamily
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
                            font.family: Config.fontFamily
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
                color: Qt.alpha(Colors.md3.outline_variant, 0.4)
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

                    MaterialIcon {
                        visible: !Config.weather?.coloredIcons
                        name: LocaleService.weatherIconName
                        iconSize: 36
                        color: LocaleService.weatherIconColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    WeatherIcon {
                        visible: Config.weather?.coloredIcons ?? false
                        code: LocaleService.weatherCode
                        isDay: LocaleService.weatherIsDay
                        iconSize: 40
                        anchors.verticalCenter: parent.verticalCenter
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

                WeatherStatGrid {
                    width: parent.width
                    fontSize: root.type.bodySmall
                    cornerSmall: root.shape.extraSmall
                    cornerLarge: root.shape.medium
                    colorDuration: root.motion.short4

                    iconFor: key => ({
                            uvi: "heat",
                            humidity: "water-drop",
                            aqi: "air",
                            feelsLike: "thermostat",
                            rain: "umbrella",
                            astro: LocaleService.activeAstroMaterialIcon
                        })[key]

                    iconColorFor: key => ({
                            uvi: root.weatherColor.heat,
                            humidity: root.weatherColor.humidity,
                            aqi: root.weatherColor.air,
                            feelsLike: Colors.md3.primary,
                            rain: root.weatherColor.rain,
                            astro: LocaleService.activeAstroColorType === "moon" ? Colors.md3.primary : root.weatherColor.sun
                        })[key]

                    textFor: key => ({
                            uvi: Localization.t("weather.uvi_value").arg(LocaleService.weatherUvi),
                            humidity: LocaleService.weatherHumid,
                            aqi: Localization.t("weather.aqi_value").arg(LocaleService.weatherAqi),
                            feelsLike: Localization.t("weather.feels_like_value").arg(LocaleService.weatherFeelsLike),
                            rain: LocaleService.weatherRainChance,
                            astro: LocaleService.activeAstroTime.replace(" AM", "").replace(" PM", "").replace(" am", "").replace(" pm", "")
                        })[key]
                }
            }

        }

        Rectangle {
            x: 16
            y: 16 + content.implicitHeight + 16
            width: 268
            height: card.implicitHeight - 32 - content.implicitHeight - 16
            radius: root.shape.large
            color: Colors.md3.surface_container

            WeatherHourScroll {
                id: hourScroll
                anchors.fill: parent
                anchors.margins: 8
            }
        }

        Rectangle {
            x: 16 + 268 + 16
            y: 16
            width: 1
            height: card.implicitHeight - 32
            color: Qt.alpha(Colors.md3.outline_variant, 0.4)
        }

        Column {
            id: calPane
            x: 16 + 268 + 33
            y: root.editorOpen ? 8 : 16
            width: 268
            spacing: 12
            opacity: root.editorOpen ? 0 : 1
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            CalendarGrid {
                id: calGrid
                firstDayOfWeek: Config.weekMonday ? 1 : 0
                isOpen: root.isOpen
                eventCounts: root.eventCounts
            }

            CalendarDayStrip {
                width: parent.width
                height: Math.max(144, content.implicitHeight + 16 + 86 - calGrid.implicitHeight - calPane.spacing)
                day: calGrid.selectedDate
                events: root.selEvents
                onAddRequested: root.openEditor(null)
                onEventClicked: ev => root.openEditor(ev)
            }
        }

        Loader {
            active: root.editorLoaded
            sourceComponent: Component {
                CalendarEditor {
                    x: 16 + 268 + 33
                    y: root.editorOpen ? 16 : 24
                    event: root.editing
                    day: calGrid.selectedDate
                    calendars: CalendarService.writableCalendars
                    height: card.implicitHeight - 32
                    opacity: root.editorOpen ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on y {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    onSaved: ev => CalendarService.save(ev, ok => {
                        if (ok)
                            root.closeEditor();
                    })
                    onDeleted: (ev, onlyThis) => {
                        const done = ok => {
                            if (ok)
                                root.closeEditor();
                        };
                        if (onlyThis)
                            CalendarService.removeOccurrence(ev.uid, ev.start, done);
                        else
                            CalendarService.remove(ev.uid, done);
                    }
                    onCancelled: root.closeEditor()
                }
            }
        }
    }
}
