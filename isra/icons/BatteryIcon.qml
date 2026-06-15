import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower

import qs.style
import qs.services 

Item {
    id: root

    width: 30
    height: 24
    property real cornerRadius: 4

    readonly property real currentPercentage: UPower.displayDevice
        ? Math.round(UPower.displayDevice.percentage * 100) : 0

    readonly property bool currentCharging: UPower.displayDevice
        ? (UPower.displayDevice.state === UPowerDeviceState.Charging) : false

    readonly property string currentPowerMode: PowerProfileService.activeProfile
    readonly property color colorBackground: Colors.md3.surface_container_high
    
    readonly property color colorUnfilledBg: {
        if (currentPowerMode === "balanced") {
            return Qt.alpha(Colors.md3.on_surface_variant, 0.5);
        } else if (currentPowerMode === "performance") {
            return Qt.alpha(Colors.md3.on_tertiary_container, 0.5);
        } else {
            return Qt.alpha(Colors.md3.on_primary_container, 0.5);
        }
    }

    readonly property color colorOnSurface: Colors.md3.on_surface
    
    readonly property color colorPrimary: Colors.md3.primary
    readonly property color colorOnPrimary: Colors.md3.on_primary
    
    readonly property color colorTertiary: Colors.md3.tertiary
    readonly property color colorOnTertiary: Colors.md3.on_tertiary
    
    readonly property color colorError: Colors.md3.error
    readonly property color colorOnError: Colors.md3.on_error

    readonly property color colorBalancedFill: Colors.md3.on_surface 
    readonly property color colorBalancedOn: Colors.md3.surface_container_highest

    readonly property bool isLow: currentPercentage < 20 && !currentCharging

    readonly property color currentFillColor: {
        if (isLow) return colorError;
        if (currentPowerMode === "saver") return colorTertiary;
        if (currentPowerMode === "performance") return colorPrimary;
        return colorBalancedFill;
    }

    readonly property color currentTextColor: {
        if (currentPowerMode === "saver") return colorOnTertiary;
        if (currentPowerMode === "performance") return colorOnPrimary;
        return colorBalancedOn;
    }

    readonly property color currentTipColor: {
        if (currentPercentage >= 100) return currentFillColor;
        return colorUnfilledBg;
    }

    ClippingRectangle {
        id: batteryBody
        width: 24
        height: 14
        radius: root.cornerRadius
        color: root.colorUnfilledBg
        anchors.left: parent.left
        anchors.leftMargin: 1
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            id: progressFill
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * (Math.max(0, Math.min(100, root.currentPercentage)) / 100)
            color: root.currentFillColor
        }

        Text {
            id: batteryText
            text: root.currentPercentage
            color: root.currentTextColor
            font.pixelSize: 12
            font.weight: Font.Black
            font.family: Config.fontFamily
            anchors.centerIn: parent
        }
    }

    Rectangle {
        id: batteryTip
        width: 2
        height: 5
        radius: 1
        color: root.currentTipColor
        anchors.left: batteryBody.right
        anchors.verticalCenter: parent.verticalCenter
        visible: !root.currentCharging
    }

    Item {
        id: boltContainer
        width: 12
        height: 14
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 0
        visible: root.currentCharging

        Shape {
            id: lightningBolt
            width: 960
            height: 960
            layer.smooth: true

            transform: [
                Scale {
                    xScale: 12 / 960
                    yScale: 12 / 960
                    origin.x: 0
                    origin.y: 0
                },
                Translate {
                    x: 0
                    y: 13
                }
            ]

            ShapePath {
                strokeColor: "transparent"
                strokeWidth: 0
                fillColor: Colors.md3.on_surface

                PathSvg {
                    path: "m 440 -380 -237 -30 q -25 -3 -32.5 -27 t 10.5 -41 l 409 -392 q 5 -5 12 -7.5 t 19 -2.5 q 20 0 30.5 17 t 0.5 35 L 520 -580 l 237 30 q 25 3 32.5 27 T 779 -482 L 370 -90 q -5 5 -12 7.5 T 339 -80 q -20 0 -30.5 -17 t -0.5 -35 l 132 -248 Z"
                }
            }

            ShapePath {
                strokeColor: root.colorBackground
                strokeWidth: 300
                fillColor: root.colorBackground 
                joinStyle: ShapePath.RoundJoin
                capStyle: ShapePath.RoundCap

                PathSvg {
                    path: "m 440 -380 -237 -30 q -25 -3 -32.5 -27 t 10.5 -41 l 409 -392 q 5 -5 12 -7.5 t 19 -2.5 q 20 0 30.5 17 t 0.5 35 L 520 -580 l 237 30 q 25 3 32.5 27 T 779 -482 L 370 -90 q -5 5 -12 7.5 T 339 -80 q -20 0 -30.5 -17 t -0.5 -35 l 132 -248 Z"
                }
            }

            ShapePath {
                strokeColor: "transparent"
                strokeWidth: 0
                fillColor: Colors.md3.on_surface

                PathSvg {
                    path: "m 440 -380 -237 -30 q -25 -3 -32.5 -27 t 10.5 -41 l 409 -392 q 5 -5 12 -7.5 t 19 -2.5 q 20 0 30.5 17 t 0.5 35 L 520 -580 l 237 30 q 25 3 32.5 27 T 779 -482 L 370 -90 q -5 5 -12 7.5 T 339 -80 q -20 0 -30.5 -17 t -0.5 -35 l 132 -248 Z"
                }
            }
        }
    }
}

