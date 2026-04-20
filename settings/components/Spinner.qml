import QtQuick
import qs.style

Item {
    id: root
    property bool running: false
    property color color: Colors.md3.primary

    implicitHeight: 2
    implicitWidth: 200
    clip: true

    opacity: running ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.color
        opacity: 0.15
    }

    Rectangle {
        id: blob1
        width: parent.width * 0.4
        height: parent.height
        color: root.color

        SequentialAnimation on x {
            running: root.running
            loops: Animation.Infinite
            NumberAnimation {
                from: -blob1.width
                to: root.width
                duration: 1200
                easing.type: Easing.InOutCubic
            }
            PauseAnimation {
                duration: 100
            }
        }
    }

    Rectangle {
        id: blob2
        width: parent.width * 0.25
        height: parent.height
        color: root.color
        opacity: 0.6

        SequentialAnimation on x {
            running: root.running
            loops: Animation.Infinite
            PauseAnimation {
                duration: 400
            }
            NumberAnimation {
                from: -blob2.width
                to: root.width
                duration: 900
                easing.type: Easing.InOutCubic
            }
        }
    }
}
