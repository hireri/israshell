pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import qs.style
import qs.services

Item {
    id: root

    property real slotWidth: 42
    property color fade: Colors.md3.surface_container
    property bool follow: true

    readonly property var hours: LocaleService.weatherHourlyWindow ?? []
    readonly property date clock: {
        LocaleService.liveTime;
        return new Date();
    }
    readonly property int nowIdx: {
        let idx = -1;
        for (let i = 0; i < hours.length; i++) {
            if (hours[i].time <= clock)
                idx = i;
        }
        return idx;
    }
    readonly property real homeX: list.originX + Math.max(0, nowIdx - 1) * slotWidth

    function clampX(x) {
        return Math.max(list.originX, Math.min(list.originX + list.contentWidth - list.width, x));
    }

    function glideTo(x) {
        glide.stop();
        glide.to = clampX(x);
        glide.start();
    }

    function recenter() {
        follow = true;
        glide.stop();
        list.cancelFlick();
        list.positionViewAtIndex(Math.max(0, nowIdx - 1), ListView.Beginning);
    }

    Component.onCompleted: Qt.callLater(recenter)
    onHoursChanged: Qt.callLater(recenter)
    onNowIdxChanged: if (follow && list.count > 0 && !list.dragging)
        glideTo(homeX)

    NumberAnimation {
        id: glide
        target: list
        property: "contentX"
        duration: 280
        easing.type: Easing.OutCubic
    }

    ListView {
        id: list
        anchors.fill: parent
        orientation: ListView.Horizontal
        clip: true
        model: root.hours

        flickDeceleration: 4000
        maximumFlickVelocity: 2200
        boundsBehavior: Flickable.DragAndOvershootBounds

        onMovementStarted: {
            glide.stop();
            root.follow = false;
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                event.accepted = true;
                root.follow = false;
                const pixel = event.pixelDelta.x !== 0 ? event.pixelDelta.x : event.pixelDelta.y;
                if (pixel !== 0) {
                    glide.stop();
                    list.cancelFlick();
                    list.contentX = root.clampX(list.contentX - pixel);
                    return;
                }
                const notch = event.angleDelta.x !== 0 ? event.angleDelta.x : event.angleDelta.y;
                root.glideTo((glide.running ? glide.to : list.contentX) - notch / 120 * root.slotWidth * 2);
            }
        }

        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property bool isNow: index === root.nowIdx
            readonly property bool past: index < root.nowIdx
            readonly property bool dayStart: modelData.time.getHours() === 0

            width: root.slotWidth
            height: list.height

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 4
                height: parent.height
                radius: width / 2
                color: Colors.md3.primary_container
                opacity: cell.isNow ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 3
                opacity: cell.past ? 0.45 : 1
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cell.modelData.temp + "°"
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: cell.isNow ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                WeatherIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    code: cell.modelData.code
                    isDay: cell.modelData.isDay
                    iconSize: 28
                    layer.enabled: cell.past
                    layer.effect: MultiEffect {
                        saturation: -1
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cell.dayStart ? Qt.locale().dayName(cell.modelData.time.getDay(), Locale.ShortFormat) : LocaleService.formatHour(cell.modelData.time)
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.weight: cell.dayStart ? Font.Bold : Font.Medium
                    color: cell.isNow ? Colors.md3.on_primary_container : cell.dayStart ? Colors.md3.primary : Colors.md3.on_surface_variant
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
            }
        }
    }

    Repeater {
        model: 2

        Rectangle {
            id: edge
            required property int index
            readonly property bool atEdge: index === 0 ? list.contentX <= list.originX + 1 : list.contentX >= list.originX + list.contentWidth - list.width - 1

            x: index === 0 ? 0 : root.width - width
            width: 20
            height: root.height
            opacity: atEdge ? 0 : 1
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: edge.index === 0 ? root.fade : Qt.alpha(root.fade, 0)
                }
                GradientStop {
                    position: 1
                    color: edge.index === 0 ? Qt.alpha(root.fade, 0) : root.fade
                }
            }
        }
    }
}
