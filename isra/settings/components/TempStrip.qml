import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
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

    Rectangle {
        id: track
        anchors.verticalCenter: stripArea.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: 6
        radius: 3

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

    Rectangle {
        id: thumb
        width: 14
        height: 14
        radius: 7
        anchors.verticalCenter: stripArea.verticalCenter
        color: Colors.md3.primary
        border.width: 2
        border.color: Colors.md3.surface
        x: sl.leftPadding + sl.visualPosition * (sl.availableWidth - width)

        Behavior on x {
            enabled: !sl.pressed
            NumberAnimation {
                duration: 80
                easing.type: Easing.OutCubic
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
            from: root.from
            to: root.to
            stepSize: root.stepSize
            value: root.value
            onMoved: root.moved(sl.value)
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
