import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets
import qs.style
import qs.services
import qs.icons
import "moon-phase.js" as MoonPhase
import "moon-ephemeris.js" as MoonEphemeris

Item {
    id: root

    property string mode: "both"
    property bool showIllumination: true

    property date now: new Date()

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    readonly property var _daily: LocaleService.weatherDaily ?? []
    readonly property var _sunrise: root._daily.length > 0 ? (root._daily[0].sunrise ?? null) : null
    readonly property var _sunset: root._daily.length > 0 ? (root._daily[0].sunset ?? null) : null
    readonly property var _hasAstro: !!root._sunrise && !!root._sunset

    readonly property bool _isDay: {
        if (!root._hasAstro)
            return true;
        const t = root.now.getTime();
        return t >= root._sunrise.getTime() && t < root._sunset.getTime();
    }

    readonly property string _sunriseLabel: LocaleService.weatherSunrise
    readonly property string _sunsetLabel: LocaleService.weatherSunset

    readonly property real _illum: MoonPhase.illumination(root.now)
    readonly property bool _waxing: MoonPhase.waxing(root.now)
    readonly property bool _southern: LocaleService.latitude < 0
    readonly property bool _mirror: root._waxing === root._southern

    readonly property var _moonTimes: MoonEphemeris.getMoonTimes(root.now, LocaleService.latitude, LocaleService.longitude)
    readonly property var _moonRise: root._moonTimes.rise ?? null
    readonly property var _moonSet: root._moonTimes.set ?? null
    readonly property string _moonriseLabel: root._moonRise ? LocaleService.formatClockTime(root._moonRise) : "—"
    readonly property string _moonsetLabel: root._moonSet ? LocaleService.formatClockTime(root._moonSet) : "—"

    readonly property real _u: {
        if (root.width <= 0 || root.height <= 0)
            return 1;
        return Math.max(0.6, Math.min(1.3, Math.min(root.width / 300, root.height / 170)));
    }

    readonly property bool _canShowBoth: root.height > 0 && (root.width / root.height) >= 1.6

    function _markerInfo(rise, set) {
        const t = root.now.getTime();
        if (!rise || !set)
            return ({
                hasArc: false,
                up: false,
                p: 0
            });

        const rTime = rise.getTime();
        const sTime = set.getTime();

        if (t >= rTime && t < sTime) {
            const p = Math.max(0, Math.min(1, (t - rTime) / Math.max(1, sTime - rTime)));
            return ({
                hasArc: true,
                up: true,
                p: p
            });
        }

        const isPastSet = t >= sTime;
        return ({
            hasArc: true,
            up: false,
            p: isPastSet ? 1 : 0
        });
    }

    readonly property var _sunMarker: root._markerInfo(root._sunrise, root._sunset)
    readonly property var _moonMarker: root._markerInfo(root._moonRise, root._moonSet)

    component SunMoonCard: Item {
        id: card

        required property string label
        required property string headerIcon
        required property color accentColor
        required property bool isMoon
        property real illumination: 0.5
        property bool mirrored: false
        required property string riseLabel
        required property string setLabel
        required property bool hasArc
        required property bool markerUp
        required property real markerP

        readonly property real u: card.width > 0 && card.height > 0 ? Math.max(0.6, Math.min(1.3, Math.min(card.width / 150, card.height / 150))) : 1
        readonly property real cardRadius: 20
        readonly property real baseY: card.height * 0.64
        readonly property real curveBaseY: card.baseY
        readonly property real topY: Math.min(30 * card.u, card.height * 0.28)
        readonly property real dayAmp: Math.max(12, Math.min(card.curveBaseY - card.topY, 70) * 0.8)

        function bump(t) {
            return (1 - Math.cos(2 * Math.PI * t)) / 2;
        }

        function hillY(p) {
            return card.curveBaseY - card.dayAmp * card.bump(p);
        }

        function fillPoly() {
            const pts = [];
            const n = 40;
            for (let i = 0; i <= n; i++) {
                const p = i / n;
                pts.push(Qt.point(p * card.width, card.hillY(p)));
            }
            pts.push(Qt.point(card.width, card.height));
            pts.push(Qt.point(0, card.height));
            return pts;
        }

        ClippingRectangle {
            id: frame
            anchors.fill: parent
            radius: Math.min(card.cardRadius, Math.min(width, height) / 2)
            color: Colors.md3.surface_container_lowest
            border.width: 1
            border.color: Qt.alpha(Colors.md3.outline, 0.5)

            Shape {
                anchors.fill: parent
                visible: card.hasArc
                preferredRendererType: Shape.CurveRenderer
                antialiasing: true

                ShapePath {
                    strokeWidth: 0
                    fillColor: Qt.alpha(card.accentColor, 0.55)
                    PathPolyline { path: card.fillPoly() }
                }
            }

            Rectangle {
                x: 0
                y: card.baseY
                width: parent.width
                height: parent.height - card.baseY
                color: Qt.alpha(Colors.md3.shadow, 0.45)
            }

            Rectangle {
                x: 0
                y: card.baseY
                width: parent.width
                height: 1
                color: Qt.alpha(Colors.md3.outline, 0.4)
            }

            Row {
                x: 14 * card.u
                y: 12 * card.u
                spacing: 6 * card.u

                MaterialIcon {
                    name: card.headerIcon
                    iconSize: 15 * card.u
                    color: Colors.md3.on_surface_variant
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: card.label
                    font.family: Config.fontFamily
                    font.pixelSize: 12 * card.u
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface_variant
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: card.isMoon && root.showIllumination
                    text: Math.round(card.illumination * 100) + "%"
                    font.family: Config.fontFamily
                    font.pixelSize: 11 * card.u
                    color: Colors.md3.on_surface_variant
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item {
                readonly property real mx: card.markerP * card.width
                readonly property real my: card.hillY(card.markerP)
                readonly property real markerSize: Math.max(14, Math.min(24, 18 * card.u))

                visible: card.hasArc
                x: mx - width / 2
                y: my - height / 2
                width: markerSize
                height: markerSize

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 2.1
                    height: width
                    radius: width / 2
                    color: Qt.alpha(card.accentColor, 0.2)
                }

                MaterialShape {
                    anchors.centerIn: parent
                    visible: !card.isMoon
                    width: parent.width
                    height: width
                    name: "sunny"
                    shapeSize: width
                    color: card.accentColor
                }

                MoonDisc {
                    anchors.fill: parent
                    visible: card.isMoon
                    illumination: card.illumination
                    mirrored: card.mirrored
                }
            }

            Item {
                x: 0
                y: card.baseY
                width: parent.width
                height: parent.height - card.baseY

                Row {
                    anchors.centerIn: parent
                    spacing: 14 * card.u

                    Row {
                        spacing: 4 * card.u
                        MaterialIcon {
                            name: "arrow-upward"
                            iconSize: 12 * card.u
                            color: Colors.md3.on_surface
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: card.riseLabel
                            font.family: Config.fontFamily
                            font.pixelSize: Math.max(9, 12 * card.u)
                            font.weight: Font.Medium
                            color: Colors.md3.on_surface
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        spacing: 4 * card.u
                        MaterialIcon {
                            name: "arrow-downward"
                            iconSize: 12 * card.u
                            color: Colors.md3.on_surface
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: card.setLabel
                            font.family: Config.fontFamily
                            font.pixelSize: Math.max(9, 12 * card.u)
                            font.weight: Font.Medium
                            color: Colors.md3.on_surface
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }

    Row {
        id: bothRow
        anchors.fill: parent
        spacing: 10 * root._u
        visible: root.mode === "both" && root._canShowBoth

        SunMoonCard {
            width: (bothRow.width - bothRow.spacing) / 2
            height: bothRow.height
            label: Localization.t("sunmoon.sun")
            headerIcon: "wb-sunny"
            accentColor: Colors.md3.primary
            isMoon: false
            riseLabel: root._sunriseLabel
            setLabel: root._sunsetLabel
            hasArc: root._sunMarker.hasArc
            markerUp: root._sunMarker.up
            markerP: root._sunMarker.p
        }

        SunMoonCard {
            width: (bothRow.width - bothRow.spacing) / 2
            height: bothRow.height
            label: Localization.t("sunmoon.moon")
            headerIcon: "moon-stars"
            accentColor: Colors.md3.tertiary
            isMoon: true
            illumination: root._illum
            mirrored: root._mirror
            riseLabel: root._moonriseLabel
            setLabel: root._moonsetLabel
            hasArc: root._moonMarker.hasArc
            markerUp: root._moonMarker.up
            markerP: root._moonMarker.p
        }
    }

    SunMoonCard {
        id: singleCard
        anchors.fill: parent
        visible: root.mode === "moon" || root.mode === "sun" || root.mode === "arc" || (root.mode === "both" && !root._canShowBoth)

        readonly property bool showMoon: root.mode === "moon" || (root.mode === "both" && !root._isDay)

        label: showMoon ? Localization.t("sunmoon.moon") : Localization.t("sunmoon.sun")
        headerIcon: showMoon ? "moon-stars" : "wb-sunny"
        accentColor: showMoon ? Colors.md3.tertiary : Colors.md3.primary
        isMoon: showMoon
        illumination: root._illum
        mirrored: root._mirror
        riseLabel: showMoon ? root._moonriseLabel : root._sunriseLabel
        setLabel: showMoon ? root._moonsetLabel : root._sunsetLabel
        hasArc: showMoon ? root._moonMarker.hasArc : root._sunMarker.hasArc
        markerUp: showMoon ? root._moonMarker.up : root._sunMarker.up
        markerP: showMoon ? root._moonMarker.p : root._sunMarker.p
    }
}