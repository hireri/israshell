import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    readonly property bool wide: root.width > root.height * 1.35

    property bool appliedWide: false
    property bool _started: false

    onWideChanged: {
        if (!root._started)
            return;
        swapSeq.restart();
    }

    Component.onCompleted: {
        root.appliedWide = root.wide;
        root._started = true;
    }

    SequentialAnimation {
        id: swapSeq
        NumberAnimation { target: face; property: "opacity"; to: 0; duration: 110; easing.type: Easing.OutCubic }
        ScriptAction { script: root.appliedWide = root.wide }
        NumberAnimation { target: face; property: "opacity"; to: 1; duration: 160; easing.type: Easing.OutCubic }
    }

    readonly property real _u: {
        if (root.width <= 0 || root.height <= 0)
            return 1;
        if (root.appliedWide)
            return Math.max(0.6, Math.min(1.5, Math.min(root.width / 310, root.height / 160)));
        return Math.max(0.6, Math.min(1.5, Math.min(root.width, root.height) / 170));
    }

    Item {
        id: face
        anchors.fill: parent

        MaterialShape {
            id: pillShape
            anchors.centerIn: parent
            visible: !root.appliedWide
            width: Math.min(parent.width, parent.height)
            height: width
            name: "pill"
            shapeSize: width
            color: Config.desktopWidgetsBlurActive ? Config.dim(Colors.md3.surface_container_high) : Colors.md3.surface_container_high
            outlined: true
            strokeColor: Qt.alpha(Colors.md3.outline, 0.5)
            strokeWidth: 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: !Config.desktopWidgetsBlurActive
                shadowBlur: 0.5
                shadowColor: Qt.alpha("black", 0.2)
                shadowVerticalOffset: 4
            }
        }

        Rectangle {
            id: wideCard
            anchors.fill: parent
            visible: root.appliedWide
            radius: height / 2
            color: Config.desktopWidgetsBlurActive ? Config.dim(Colors.md3.surface_container_high) : Colors.md3.surface_container_high
            border.width: 1
            border.color: Qt.alpha(Colors.md3.outline, 0.5)

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: !Config.desktopWidgetsBlurActive
                shadowBlur: 0.5
                shadowColor: Qt.alpha("black", 0.2)
                shadowVerticalOffset: 4
            }
        }

        Column {
            anchors.centerIn: parent
            visible: !root.appliedWide
            spacing: -22 * root._u

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: 16 * root._u
                text: WeatherReadout.temp
                font.family: Config.fontFamily
                font.pixelSize: 58 * root._u
                font.weight: Font.Medium
                color: Colors.md3.primary
            }

            WeatherIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: -22 * root._u
                code: WeatherReadout.code
                isDay: WeatherReadout.isDay
                iconSize: 74 * root._u
            }
        }

        Row {
            anchors.centerIn: parent
            visible: root.appliedWide
            spacing: 16 * root._u

            WeatherIcon {
                anchors.verticalCenter: parent.verticalCenter
                code: WeatherReadout.code
                isDay: WeatherReadout.isDay
                iconSize: 116 * root._u
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1 * root._u

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: WeatherReadout.temp
                    font.family: Config.fontFamily
                    font.pixelSize: 54 * root._u
                    font.weight: Font.DemiBold
                    color: Colors.md3.primary
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 7 * root._u

                    Text {
                        text: WeatherReadout.high
                        font.family: Config.fontFamily
                        font.pixelSize: 18 * root._u
                        font.weight: Font.Medium
                        color: Colors.md3.primary
                    }

                    Text {
                        text: WeatherReadout.low
                        font.family: Config.fontFamily
                        font.pixelSize: 18 * root._u
                        font.weight: Font.Medium
                        color: Colors.md3.tertiary
                    }
                }
            }
        }
    }
}
