import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.style

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

    property real _cx: modelData.width * 0.82
    property real _cy: modelData.height * 0.10

    function updatePosition() {
        const pos = Config.clockPositions[modelData.name];
        if (pos) {
            _cx = pos.x;
            _cy = pos.y;
        }
    }

    Connections {
        target: Config
        function onClockPositionsChanged() {
            updatePosition();
        }
    }

    Component.onCompleted: {
        updatePosition();
    }

    Item {
        id: clockRoot
        x: root._cx - width / 2
        y: root._cy - height / 2

        Behavior on x {
            enabled: !Config.loading
            NumberAnimation {
                duration: 600
                easing.type: Easing.InOutCubic
            }
        }
        Behavior on y {
            enabled: !Config.loading
            NumberAnimation {
                duration: 600
                easing.type: Easing.InOutCubic
            }
        }

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

        implicitWidth: root._vert ? Math.max(hoursLbl.implicitWidth, minsLbl.implicitWidth, Config.clock.showDate ? dateLbl.implicitWidth : 0) : timeRow.implicitWidth
        implicitHeight: root._vert ? hoursLbl.implicitHeight + Config.clock.timeSpacing + minsLbl.implicitHeight + (Config.clock.showDate ? Config.clock.dateSpacing + dateLbl.implicitHeight : 0) : timeRow.implicitHeight + (Config.clock.showDate ? Config.clock.dateSpacing + dateLbl.implicitHeight : 0)

        Text {
            id: hoursLbl
            visible: root._vert
            anchors.horizontalCenter: parent.horizontalCenter
            font {
                family: clockRoot._font
                pixelSize: Config.clock.hourSize
                weight: Config.clock.hourWeight ?? Font.Bold
            }
            color: clockRoot._textColor
            horizontalAlignment: clockRoot._halign
            text: root._hours()
        }

        Text {
            id: minsLbl
            visible: root._vert
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: hoursLbl.bottom
                topMargin: Config.clock.timeSpacing
            }
            font {
                family: clockRoot._font
                pixelSize: Config.clock.minuteSize
                weight: Config.clock.minuteWeight ?? Font.Light
            }
            color: clockRoot._subColor
            horizontalAlignment: clockRoot._halign
            text: root._minutes()
        }

        Row {
            id: timeRow
            visible: !root._vert
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Config.clock.timeSpacing > 0 ? Config.clock.timeSpacing : 8

            Text {
                font {
                    family: clockRoot._font
                    pixelSize: Config.clock.hourSize
                    weight: Config.clock.hourWeight ?? Font.Bold
                }
                color: clockRoot._textColor
                text: root._hours()
            }
            Text {
                font {
                    family: clockRoot._font
                    pixelSize: Config.clock.hourSize
                    weight: Config.clock.minuteWeight ?? Font.Light
                }
                color: clockRoot._subColor
                text: ":"
            }
            Text {
                font {
                    family: clockRoot._font
                    pixelSize: Config.clock.hourSize
                    weight: Config.clock.minuteWeight ?? Font.Light
                }
                color: clockRoot._subColor
                text: root._minutes()
            }
        }

        Text {
            id: dateLbl
            visible: Config.clock.showDate
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: root._vert ? minsLbl.bottom : timeRow.bottom
                topMargin: Config.clock.dateSpacing
            }
            font {
                family: clockRoot._font
                pixelSize: Config.clock.dateSize
                weight: Font.Normal
            }
            color: clockRoot._subColor
            opacity: 0.7
            horizontalAlignment: clockRoot._halign
            text: Qt.formatDate(new Date(), ["ddd, dd/MM", "ddd, MM/dd"][Config.dateFormat] ?? "ddd, dd/MM")
        }
    }

    readonly property bool _vert: Config.clock.layout !== "horizontal"
    function _hours() {
        const h = new Date().getHours();
        const use12 = Config.hourFormat !== 0;
        const disp = use12 ? (h % 12 || 12) : h;
        return String(disp).padStart(2, "0");
    }

    function _minutes() {
        const d = new Date();
        const h = d.getHours();
        const m = String(d.getMinutes()).padStart(2, "0");

        if (Config.clock?.layout !== "horizontal" || Config.hourFormat === 0) {
            return m;
        }

        const isPM = h >= 12;
        const suffix = Config.hourFormat === 2 ? (isPM ? " PM" : " AM") : (isPM ? " pm" : " am");

        return m + suffix;
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            hoursLbl.text = root._hours();
            minsLbl.text = root._minutes();
            dateLbl.text = Qt.formatDate(new Date(), ["ddd, dd/MM", "ddd, MM/dd"][Config.dateFormat] ?? "ddd, dd/MM");
        }
    }
}
