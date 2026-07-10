import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell.Widgets
import qs.style

Item {
    id: root

    property real from: 1000
    property real to: 6500
    property real stepSize: 100
    property real value: 4000

    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 52

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 20

        Text {
            text: Math.round(root.from) + "K"
            font.family: Config.fontFamily
            font.pixelSize: 10
            color: Colors.md3.outline
            opacity: 0.6
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            text: Math.round(sl.value) + "K"
            font.family: Config.fontFamily
            font.pixelSize: 11
            font.weight: Font.Medium
            color: Colors.md3.on_surface
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            text: Math.round(root.to) + "K"
            font.family: Config.fontFamily
            font.pixelSize: 10
            color: Colors.md3.outline
            opacity: 0.6
        }
    }

    Item {
        id: track
        anchors.verticalCenter: stripArea.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: 8

        property bool hover: sl.hovered || sl.pressed
        property real thumbW: hover ? 3 : 0
        property real thumbGap: hover ? 4 : 2
        readonly property real leftWidth: sl.visualPosition * (width - thumbW - thumbGap * 2)

        Behavior on thumbW {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        Behavior on thumbGap {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        ClippingRectangle {
            id: leftClip
            x: 0
            width: track.leftWidth
            height: parent.height
            radius: 4
            color: "transparent"

            Rectangle {
                width: track.width
                height: parent.height
                radius: 4

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: "#ff8c42"
                    }
                    GradientStop {
                        position: 0.4
                        color: "#ffe4b5"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#c8e8ff"
                    }
                }
            }
        }

        ClippingRectangle {
            id: thumbRect
            anchors.verticalCenter: parent.verticalCenter
            x: track.leftWidth + track.thumbGap
            width: track.thumbW
            height: track.hover ? 18 : 14
            radius: 1
            color: "transparent"

            Behavior on height {
                NumberAnimation {
                    duration: 150
                }
            }

            Rectangle {
                x: -(track.leftWidth + track.thumbGap)
                width: track.width
                height: parent.height

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: "#ff8c42"
                    }
                    GradientStop {
                        position: 0.4
                        color: "#ffe4b5"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#c8e8ff"
                    }
                }
            }
        }

        ClippingRectangle {
            id: rightClip
            x: thumbRect.x + thumbRect.width + track.thumbGap
            width: Math.max(0, track.width - x)
            height: parent.height
            radius: 4
            color: "transparent"

            Rectangle {
                x: -rightClip.x
                width: track.width
                height: parent.height
                radius: 4

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: "#ff8c42"
                    }
                    GradientStop {
                        position: 0.4
                        color: "#ffe4b5"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#c8e8ff"
                    }
                }
            }
        }
    }

    Item {
        id: stripArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 32

        Slider {
            id: sl
            anchors.fill: parent
            hoverEnabled: true
            from: root.from
            to: root.to
            stepSize: root.stepSize
            value: root.value
            onMoved: root.moved(sl.value)

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            background: Item {}
            handle: Item {
                x: sl.leftPadding + sl.visualPosition * (sl.availableWidth - width)
                y: sl.topPadding + sl.availableHeight / 2 - height / 2
                width: 14
                height: 14
            }
        }
    }
}
