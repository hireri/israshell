import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.style
import qs.services

PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"
    visible: Config.desktopClock
    WlrLayershell.namespace: "quickshell:clock"
    WlrLayershell.layer: WlrLayer.Bottom
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    property real _cx: 0
    property real _cy: 0

    Behavior on _cx {
        enabled: !Config.loading
        NumberAnimation {
            duration: 600
            easing.type: Easing.InOutCubic
        }
    }
    Behavior on _cy {
        enabled: !Config.loading
        NumberAnimation {
            duration: 600
            easing.type: Easing.InOutCubic
        }
    }

    property var _currentTime: new Date()

    function updatePosition() {
        const pos = Config.clockPositions?.[modelData.name];
        if (!pos || (pos.x === _cx && pos.y === _cy))
            return;
        _cx = pos.x;
        _cy = pos.y;
    }

    Connections {
        target: Config
        function onClockPositionsChanged() {
            updatePosition();
        }
    }

    Component.onCompleted: {
        updatePosition();
        if (!Config.clockPositions?.[modelData.name]) {
            _cx = modelData.width * 0.82;
            _cy = modelData.height * 0.10;
        }
        if (modelData === Quickshell.screens[0])
            WallpaperService.reportClockSize(clockRoot.implicitWidth, clockRoot.implicitHeight);
    }

    Connections {
        target: clockRoot
        function onImplicitWidthChanged() {
            if (root.modelData === Quickshell.screens[0])
                Qt.callLater(() => WallpaperService.reportClockSize(clockRoot.implicitWidth, clockRoot.implicitHeight));
        }
        function onImplicitHeightChanged() {
            if (root.modelData === Quickshell.screens[0])
                Qt.callLater(() => WallpaperService.reportClockSize(clockRoot.implicitWidth, clockRoot.implicitHeight));
        }
    }

    Timer {
        interval: clockRoot._layoutMode === 3 ? 50 : 500
        running: true
        repeat: true
        onTriggered: {
            const now = new Date();
            if (clockRoot._layoutMode === 3) {
                root._currentTime = now;
            } else if (clockRoot._layoutMode === 1) {
                if (now.getMinutes() !== root._currentTime.getMinutes())
                    root._currentTime = now;
            } else {
                root._currentTime = now;
            }
        }
    }

    Item {
        id: clockRoot
        x: root._cx - width / 2
        y: root._cy - height / 2

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: Config.clock.shadowBlur ?? 16
            samples: 32
            color: Qt.alpha("black", 0.2)
        }

        readonly property string _font: Config.clock.fontFamily !== "" ? Config.clock.fontFamily : Config.fontFamily
        readonly property color _textColor: Colors.md3[Config.clock.colorRole] ?? Colors.md3.on_surface
        readonly property color _subColor: Colors.md3[Config.clock.subColorRole] ?? Colors.md3.on_surface_variant
        readonly property int _halign: Config.clock.align === "left" ? Text.AlignLeft : Config.clock.align === "right" ? Text.AlignRight : Text.AlignHCenter
        readonly property int _layoutMode: Config.clock.layout === "horizontal" ? 0 : Config.clock.layout === "vertical" ? 1 : Config.clock.layout === "word" ? 2 : Config.clock.layout === "analog" ? 3 : 0
        readonly property int _analogSize: Config.clock.analogSize ?? 200
        readonly property bool _showSeconds: Config.clock.showSeconds ?? false
        readonly property bool _is12h: Config.hourFormat !== 0

        implicitWidth: _layoutMode === 0 ? timeRow.implicitWidth : _layoutMode === 1 ? Math.max(hoursLbl.implicitWidth, minsLbl.implicitWidth, Config.clock.showDate ? dateLbl.implicitWidth : 0) : _layoutMode === 2 ? wordClock.implicitWidth : analogClock.width
        implicitHeight: {
            let base = 0;
            switch (_layoutMode) {
            case 0:
                base = timeRow.implicitHeight;
                break;
            case 1:
                base = hoursLbl.implicitHeight + Config.clock.timeSpacing + minsLbl.implicitHeight;
                break;
            case 2:
                base = wordClock.implicitHeight;
                break;
            case 3:
                base = analogClock.height;
                break;
            }
            return base + (Config.clock.showDate ? Config.clock.dateSpacing + dateLbl.implicitHeight : 0);
        }

        Text {
            id: hoursLbl
            visible: clockRoot._layoutMode === 1
            anchors.horizontalCenter: parent.horizontalCenter
            font {
                family: clockRoot._font
                pixelSize: Config.clock.hourSize
                weight: Config.clock.hourWeight ?? Font.Bold
            }
            color: clockRoot._textColor
            text: root._formatHours(root._currentTime)
        }

        Text {
            id: minsLbl
            visible: clockRoot._layoutMode === 1
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: hoursLbl.bottom
                topMargin: Config.clock.timeSpacing
            }
            font {
                family: clockRoot._font
                pixelSize: Config.clock.minuteSize
                weight: Config.clock.minuteWeight ?? Font.Medium
            }
            color: clockRoot._subColor
            text: root._formatMinutes(root._currentTime)
        }

        RowLayout {
            id: timeRow
            visible: clockRoot._layoutMode === 0
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Text {
                Layout.alignment: Qt.AlignBaseline
                font {
                    family: clockRoot._font
                    pixelSize: Config.clock.hourSize ?? 64
                    weight: Config.clock.hourWeight ?? Font.Bold
                    letterSpacing: -1
                }
                color: clockRoot._textColor
                text: root._formatHours(root._currentTime)
            }
            Text {
                Layout.alignment: Qt.AlignBaseline
                font {
                    family: clockRoot._font
                    pixelSize: Config.clock.hourSize ?? 64
                    weight: Font.Medium
                }
                color: Qt.alpha(clockRoot._textColor, 0.6)
                text: ":"
            }
            Text {
                id: minTxt
                Layout.alignment: Qt.AlignBaseline
                font {
                    family: clockRoot._font
                    pixelSize: Config.clock.hourSize ?? 64
                    weight: Config.clock.minuteWeight ?? Font.DemiBold
                    letterSpacing: -1
                }
                color: clockRoot._textColor
                text: root._formatMinutes(root._currentTime)
            }
            Text {
                visible: clockRoot._showSeconds
                Layout.alignment: Qt.AlignBaseline
                font {
                    family: clockRoot._font
                    pixelSize: (Config.clock.hourSize ?? 64) * 0.55
                    weight: Font.Medium
                }
                color: clockRoot._subColor
                text: ":" + root._formatSeconds(root._currentTime)
            }
            Item {
                visible: clockRoot._is12h
                Layout.preferredWidth: 4
            }
            Text {
                visible: clockRoot._is12h
                Layout.alignment: Qt.AlignBaseline
                font {
                    family: clockRoot._font
                    pixelSize: (Config.clock.hourSize ?? 64) * 0.35
                    weight: Font.Bold
                    letterSpacing: 0.5
                }
                color: clockRoot._subColor
                text: root._currentTime.getHours() >= 12 ? (Config.hourFormat === 2 ? "PM" : "pm") : (Config.hourFormat === 2 ? "AM" : "am")
            }
        }

        ColumnLayout {
            id: wordClock
            visible: clockRoot._layoutMode === 2
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Config.clock.wordSpacing ?? -6

            Repeater {
                id: wordRepeater
                model: root._wordClockLines()
                Row {
                    Layout.alignment: clockRoot._halign === Text.AlignLeft ? Qt.AlignLeft : (clockRoot._halign === Text.AlignRight ? Qt.AlignRight : Qt.AlignHCenter)
                    spacing: 8

                    Repeater {
                        model: modelData.words
                        Text {
                            text: modelData.text
                            font {
                                family: clockRoot._font
                                pixelSize: (Config.clock.hourSize ?? 48) * 0.55
                                weight: modelData.isNumber ? Font.Bold : Font.Medium
                            }
                            color: {
                                if (!modelData.active)
                                    return Qt.alpha(clockRoot._subColor, 0.25);
                                return modelData.isNumber ? clockRoot._textColor : clockRoot._subColor;
                            }
                            opacity: modelData.active ? 1.0 : 0.35
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.InOutCubic
                                }
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 400
                                    easing.type: Easing.InOutCubic
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: analogClock
            visible: clockRoot._layoutMode === 3
            anchors.horizontalCenter: parent.horizontalCenter
            width: clockRoot._analogSize
            height: clockRoot._analogSize

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Colors.md3.surface_container_high ?? Colors.md3.surface_container ?? Qt.rgba(0.95, 0.95, 0.95, 1)

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    radius: Config.clock.shadowBlur ?? 16
                    samples: 32
                    color: Qt.alpha("black", 0.15)
                }
            }

            Repeater {
                model: 12
                Item {
                    anchors.fill: parent
                    rotation: index * 30
                    Rectangle {
                        width: 6
                        height: index % 3 === 0 ? 10 : 6
                        radius: width / 2
                        color: index % 3 === 0 ? Qt.alpha(clockRoot._subColor, 0.6) : Qt.alpha(clockRoot._subColor, 0.3)
                        anchors.top: parent.top
                        anchors.topMargin: 16
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            Item {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                rotation: root._currentTime.getMinutes() * 6 + root._currentTime.getSeconds() * 0.1 + root._currentTime.getMilliseconds() * (0.1 / 1000)

                Rectangle {
                    width: clockRoot._analogSize * 0.05
                    height: clockRoot._analogSize * 0.38 + width
                    radius: width / 2
                    color: clockRoot._subColor
                    anchors.bottom: parent.verticalCenter
                    anchors.bottomMargin: -radius
                    anchors.horizontalCenter: parent.horizontalCenter
                    antialiasing: true
                }
            }

            Item {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                rotation: (root._currentTime.getHours() % 12) * 30 + root._currentTime.getMinutes() * 0.5 + root._currentTime.getSeconds() * (0.5 / 60)

                Rectangle {
                    width: clockRoot._analogSize * 0.08
                    height: clockRoot._analogSize * 0.25 + width
                    radius: width / 2
                    color: clockRoot._textColor
                    anchors.bottom: parent.verticalCenter
                    anchors.bottomMargin: -radius
                    anchors.horizontalCenter: parent.horizontalCenter
                    antialiasing: true
                }
            }

            Item {
                visible: clockRoot._showSeconds
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                rotation: root._currentTime.getSeconds() * 6 + root._currentTime.getMilliseconds() * 0.006

                Rectangle {
                    width: clockRoot._analogSize * 0.08
                    height: width
                    radius: width / 2
                    color: Colors.md3.tertiary ?? Colors.md3.error ?? "#ff6b6b"
                    y: clockRoot._analogSize * 0.15
                    anchors.horizontalCenter: parent.horizontalCenter
                    antialiasing: true
                }
            }

            Rectangle {
                width: clockRoot._analogSize * 0.05
                height: width
                radius: width / 2
                color: clockRoot._textColor
                anchors.centerIn: parent
                z: 10
                antialiasing: true
            }
        }

        Text {
            id: dateLbl
            visible: Config.clock.showDate
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: clockRoot._layoutMode === 1 ? minsLbl.bottom : clockRoot._layoutMode === 0 ? timeRow.bottom : clockRoot._layoutMode === 2 ? wordClock.bottom : analogClock.bottom
                topMargin: Config.clock.dateSpacing
            }
            font {
                family: clockRoot._font
                pixelSize: Config.clock.dateSize
                weight: Font.Normal
            }
            color: clockRoot._subColor
            opacity: 0.8
            text: Qt.formatDate(root._currentTime, ["ddd, dd/MM", "ddd, MM/dd"][Config.dateFormat] ?? "ddd, dd/MM")
        }
    }

    function _formatHours(d) {
        const h = d.getHours();
        return String(Config.hourFormat !== 0 ? (h % 12 || 12) : h).padStart(2, "0");
    }
    function _formatMinutes(d) {
        return String(d.getMinutes()).padStart(2, "0");
    }
    function _formatSeconds(d) {
        return String(d.getSeconds()).padStart(2, "0");
    }

    function _wordClockLines() {
        const now = new Date();
        let h = now.getHours(), mi = now.getMinutes();
        const r = mi % 5, m = r >= 3 ? (mi + (5 - r)) % 60 || 0 : mi - r;
        const dh = (r >= 3 && mi + (5 - r) >= 60) ? (h + 1) % 24 : h;
        const displayHour = dh % 12 || 12, nextHour = (displayHour % 12) + 1;
        const names = ["", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE"];
        const w = (text, active) => ({
                    text,
                    active,
                    isNumber: names.includes(text)
                });
        const itis = [w("IT", true), w("IS", true)];

        if (m === 0)
            return [
                {
                    words: itis
                },
                {
                    words: [w(names[displayHour], true)]
                },
                {
                    words: [w("OCLOCK", true)]
                }
            ];
        if (m === 5)
            return [
                {
                    words: itis
                },
                {
                    words: [w("FIVE", true)]
                },
                {
                    words: [w("PAST", true), w(names[displayHour], true)]
                }
            ];
        if (m === 10)
            return [
                {
                    words: itis
                },
                {
                    words: [w("TEN", true)]
                },
                {
                    words: [w("PAST", true), w(names[displayHour], true)]
                }
            ];
        if (m === 15)
            return [
                {
                    words: itis
                },
                {
                    words: [w("QUARTER", true)]
                },
                {
                    words: [w("PAST", true), w(names[displayHour], true)]
                }
            ];
        if (m === 20)
            return [
                {
                    words: itis
                },
                {
                    words: [w("TWENTY", true)]
                },
                {
                    words: [w("PAST", true), w(names[displayHour], true)]
                }
            ];
        if (m === 25)
            return [
                {
                    words: itis
                },
                {
                    words: [w("TWENTY", true), w("FIVE", true)]
                },
                {
                    words: [w("PAST", true), w(names[displayHour], true)]
                }
            ];
        if (m === 30)
            return [
                {
                    words: itis
                },
                {
                    words: [w("HALF", true)]
                },
                {
                    words: [w("PAST", true), w(names[displayHour], true)]
                }
            ];
        if (m === 35)
            return [
                {
                    words: itis
                },
                {
                    words: [w("TWENTY", true), w("FIVE", true)]
                },
                {
                    words: [w("TO", true), w(names[nextHour], true)]
                }
            ];
        if (m === 40)
            return [
                {
                    words: itis
                },
                {
                    words: [w("TWENTY", true)]
                },
                {
                    words: [w("TO", true), w(names[nextHour], true)]
                }
            ];
        if (m === 45)
            return [
                {
                    words: itis
                },
                {
                    words: [w("QUARTER", true)]
                },
                {
                    words: [w("TO", true), w(names[nextHour], true)]
                }
            ];
        if (m === 50)
            return [
                {
                    words: itis
                },
                {
                    words: [w("TEN", true)]
                },
                {
                    words: [w("TO", true), w(names[nextHour], true)]
                }
            ];
        if (m === 55)
            return [
                {
                    words: itis
                },
                {
                    words: [w("FIVE", true)]
                },
                {
                    words: [w("TO", true), w(names[nextHour], true)]
                }
            ];
        return [
            {
                words: itis
            }
        ];
    }

    Timer {
        interval: 60000
        running: clockRoot._layoutMode === 2
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (clockRoot._layoutMode === 2)
                wordRepeater.model = root._wordClockLines();
        }
    }
}
