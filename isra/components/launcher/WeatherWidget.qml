import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    property string query: ""
    readonly property bool hasResult: true

    readonly property var _liveData: ({
        temp: LocaleService.weatherTemp,
        high: LocaleService.weatherHigh,
        low: LocaleService.weatherLow,
        desc: LocaleService.weatherDesc,
        iconName: (LocaleService.weatherError !== "") ? "brightness-alert" : LocaleService.weatherIconName,
        iconColor: LocaleService.weatherIconColor,
        uvi: LocaleService.weatherUvi,
        humidity: LocaleService.weatherHumid,
        aqi: LocaleService.weatherAqi,
        feelsLike: LocaleService.weatherFeelsLike,
        rainChance: LocaleService.weatherRainChance,
        location: Config.cityName || "Local Forecast",
        astroIcon: LocaleService.activeAstroMaterialIcon,
        astroColor: LocaleService.activeAstroColorType === "moon" ? root.weatherColor.air : root.weatherColor.sun,
        astroTime: LocaleService.activeAstroTime,
        loading: LocaleService.weatherLoading,
        error: LocaleService.weatherError !== ""
    })

    readonly property var _searchedData: ({
        temp: _searchedTemp,
        high: _searchedHigh,
        low: _searchedLow,
        desc: _searchedDesc,
        iconName: _searchError ? "brightness-alert" : _searchedIconName,
        iconColor: _searchedIconColor,
        uvi: _searchedUvi,
        humidity: _searchedHumidity,
        aqi: _searchedAqi,
        feelsLike: _searchedFeelsLike,
        rainChance: _searchedRainChance,
        location: _searchedLocation,
        astroIcon: _searchedAstroIcon,
        astroColor: _searchedAstroColorType === "moon" ? root.weatherColor.air : root.weatherColor.sun,
        astroTime: _searchedAstroTime,
        loading: _searchLoading,
        error: _searchError
    })

    readonly property var weatherData: query === "" ? _liveData : _searchedData

    property string _searchedTemp: "—"
    property string _searchedHigh: "—"
    property string _searchedLow: "—"
    property string _searchedDesc: "loading…"
    property string _searchedIconName: "partly-cloudy-day"
    property color _searchedIconColor: Colors.md3.on_surface_variant
    property string _searchedUvi: "—"
    property string _searchedHumidity: "—"
    property string _searchedAqi: "—"
    property string _searchedFeelsLike: "—"
    property string _searchedRainChance: "—"
    property string _searchedAstroTime: "—"
    property string _searchedAstroIcon: "wb-twilight"
    property string _searchedAstroColorType: "sun"
    property string _searchedLocation: "loading…"

    property bool _searchLoading: false
    property bool _searchError: false
    property int _searchSeq: 0

    readonly property var shape: ({
        extraSmall: 4,
        small: 8,
        medium: 12,
        large: 16,
        extraLarge: 28,
        full: 9999
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

    onQueryChanged: {
        debounce.stop();

        _searchedTemp = "—"
        _searchedHigh = "—"
        _searchedLow = "—"
        _searchedDesc = "loading…"
        _searchedIconName = "partly-cloudy-day"
        _searchedIconColor = Colors.md3.on_surface_variant
        _searchedUvi = "—"
        _searchedHumidity = "—"
        _searchedAqi = "—"
        _searchedFeelsLike = "—"
        _searchedRainChance = "—"
        _searchedAstroTime = "—"
        _searchedAstroIcon = "wb-twilight"
        _searchedAstroColorType = "sun"
        _searchedLocation = "loading…"

        if (query.trim() !== "") {
            _searchLoading = true;
            _searchError = false;
            debounce.restart();
        } else {
            _searchLoading = false;
            _searchError = false;
        }
    }

    Timer {
        id: debounce
        interval: 380
        onTriggered: root._fetchWeather()
    }

    function _fetchWeather() {
        const city = query.trim();
        if (city === "") return;

        const currentSeq = ++root._searchSeq;

        LocaleService.fetchWeatherForQuery(city, function (error, result) {
            if (currentSeq !== root._searchSeq) return;

            root._searchLoading = false;
            if (error) {
                root._searchError = true;
                return;
            }

            root._searchedTemp = result.temp;
            root._searchedFeelsLike = result.feelsLike;
            root._searchedHigh = result.high;
            root._searchedLow = result.low;
            root._searchedHumidity = result.humidity;
            root._searchedUvi = result.uvi;
            root._searchedRainChance = result.rainChance;
            root._searchedAstroTime = result.astroTime;
            root._searchedAstroIcon = result.astroIcon;
            root._searchedAstroColorType = result.astroColorType;
            root._searchedLocation = result.location;
            root._searchedDesc = result.desc;
            root._searchedIconName = result.iconName;
            root._searchedIconColor = result.iconColor;
            root._searchedAqi = result.aqi;
        });
    }

    implicitHeight: content.implicitHeight

    Column {
        id: content
        width: parent.width
        spacing: 12

        Row {
            width: parent.width
            spacing: 16

            MaterialIcon {
                name: root.weatherData.iconName
                iconSize: 36
                color: root.weatherData.iconColor
                anchors.verticalCenter: parent.verticalCenter
                transitionType: "none"
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Row {
                    spacing: 8

                    Text {
                        id: tempLabel
                        text: root.weatherData.temp
                        font.pixelSize: root.type.headlineSmall
                        color: Colors.md3.on_surface
                        font.family: Config.fontFamily
                    }

                    Text {
                        text: root.weatherData.high + " / " + root.weatherData.low
                        font.pixelSize: root.type.bodyMedium
                        font.weight: Font.Medium
                        color: Colors.md3.on_surface_variant
                        font.family: Config.fontFamily
                        anchors.baseline: tempLabel.baseline
                    }

                    Rectangle {
                        visible: root.weatherData.loading
                        width: 6
                        height: 6
                        radius: 3
                        color: Colors.md3.primary
                        anchors.verticalCenter: tempLabel.verticalCenter
                        opacity: 0.7
                        SequentialAnimation on opacity {
                            running: root.weatherData.loading
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 0.2
                                duration: 500
                            }
                            NumberAnimation {
                                to: 0.8
                                duration: 500
                            }
                        }
                    }
                }

                Text {
                    text: root.weatherData.error ? Localization.t("weather.failed_to_load") : root.weatherData.desc
                    font.pixelSize: root.type.bodySmall
                    font.weight: Font.Medium
                    color: root.weatherData.error ? Colors.md3.error : Colors.md3.on_surface_variant
                    font.family: Config.fontFamily
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
                color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
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
                        text: Localization.t("weather.uvi_value").arg(root.weatherData.uvi)
                        color: Colors.md3.on_surface_variant
                        font.family: Config.fontFamily
                        font.pixelSize: root.type.bodySmall
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                width: weatherGrid.cellWidth
                height: weatherGrid.cellHeight
                color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
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
                        text: root.weatherData.humidity
                        color: Colors.md3.on_surface_variant
                        font.family: Config.fontFamily
                        font.pixelSize: root.type.bodySmall
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                width: weatherGrid.cellWidth
                height: weatherGrid.cellHeight
                color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
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
                        text: Localization.t("weather.aqi_value").arg(root.weatherData.aqi)
                        color: Colors.md3.on_surface_variant
                        font.family: Config.fontFamily
                        font.pixelSize: root.type.bodySmall
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                width: weatherGrid.cellWidth
                height: weatherGrid.cellHeight
                color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
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
                        text: Localization.t("weather.feels_like_value").arg(root.weatherData.feelsLike)
                        color: Colors.md3.on_surface_variant
                        font.family: Config.fontFamily
                        font.pixelSize: root.type.bodySmall
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                width: weatherGrid.cellWidth
                height: weatherGrid.cellHeight
                color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
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
                        text: root.weatherData.rainChance
                        color: Colors.md3.on_surface_variant
                        font.family: Config.fontFamily
                        font.pixelSize: root.type.bodySmall
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                width: weatherGrid.cellWidth
                height: weatherGrid.cellHeight
                color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
                radius: root.shape.extraSmall
                bottomRightRadius: root.shape.medium

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialIcon {
                        name: root.weatherData.astroIcon
                        iconSize: 14
                        color: root.weatherData.astroColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.weatherData.astroTime
                        color: Colors.md3.on_surface_variant
                        font.family: Config.fontFamily
                        font.pixelSize: root.type.bodySmall
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}