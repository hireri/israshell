import QtQuick
import qs.style
import qs.icons

Item {
    id: root

    property bool running: true
    property real size: 16
    property color color: Colors.md3.primary
    property bool background: false
    property color backgroundColor: Qt.alpha(root.color, 0.15)
    property var shapes: ["pill", "sunny", "cookie4", "oval", "softBurst", "cookie9", "pentagon"]

    implicitWidth: root.size
    implicitHeight: root.size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        visible: root.background
        color: root.backgroundColor
    }

    MaterialShape {
        id: shape
        anchors.centerIn: parent
        shapeSize: root.background ? root.size * 0.55 : root.size
        color: root.color
        shapes: root.shapes

        property real _cycleStart: 0

        SequentialAnimation on rotation {
            running: root.running && root.visible
            loops: Animation.Infinite
            NumberAnimation {
                from: shape._cycleStart
                to: shape._cycleStart + 45
                duration: 650
                easing.type: Easing.Linear
            }
            NumberAnimation {
                from: shape._cycleStart + 45
                to: shape._cycleStart + 85
                duration: 150
                easing.type: Easing.InQuad
            }
            ScriptAction {
                script: shape.roundedPolygon = shape._pick()
            }
            NumberAnimation {
                from: shape._cycleStart + 85
                to: shape._cycleStart + 100
                duration: 200
                easing.type: Easing.OutQuad
            }
            ScriptAction {
                script: shape._cycleStart = (shape._cycleStart + 100) % 360
            }
        }
    }
}
