import QtQuick
import QtQuick.Controls.Basic
import qs.style

Slider {
    id: control

    property color fillColor: Colors.md3.primary
    property color trackColor: Colors.md3.surface_variant
    property real trackHeight: 6
    property real thumbWidth: 3
    property real thumbGapIdle: 2
    property real thumbGapHover: 4
    property real thumbHeightIdle: 14
    property real thumbHeightHover: 18

    implicitHeight: 24
    hoverEnabled: true

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    background: Item {
        id: track
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.availableWidth
        height: control.trackHeight

        property bool hover: control.hovered || control.pressed
        property real thumbW: hover ? control.thumbWidth : 0
        property real thumbGap: hover ? control.thumbGapHover : control.thumbGapIdle

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

        Rectangle {
            id: barLeft
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            width: control.visualPosition * (track.width - track.thumbW - track.thumbGap * 2)
            height: track.height
            radius: height / 2
            color: control.fillColor
        }

        Rectangle {
            id: thumbRect
            anchors.verticalCenter: parent.verticalCenter
            x: barLeft.width + track.thumbGap
            width: track.thumbW
            height: track.hover ? control.thumbHeightHover : control.thumbHeightIdle
            radius: 1
            color: control.fillColor

            Behavior on height {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        Rectangle {
            anchors {
                left: thumbRect.right
                leftMargin: track.thumbGap
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            height: track.height
            radius: height / 2
            color: control.trackColor
        }
    }

    handle: Item {}
}
