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
    property var shapes: ["softBurst", "cookie9", "pentagon", "pill", "sunny", "cookie4", "oval"]

    implicitWidth: root.size
    implicitHeight: root.size

    readonly property bool _spinning: root.running && root.visible

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
        name: root.shapes.length > 0 ? root.shapes[0] : ""
        rotationAnimates: false

        property int _index: 0
        property real _kick: 0
        property real _target: 0
        property real _spin: 0

        rotation: shape._kick + shape._target + shape._spin

        NumberAnimation on _spin {
            running: root._spinning
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 4666
            easing.type: Easing.Linear
        }

        SequentialAnimation {
            running: root._spinning
            loops: Animation.Infinite

            NumberAnimation {
                target: shape
                property: "_kick"
                from: 0
                to: 65
                duration: 300
                easing.type: Easing.InSine
            }
            ScriptAction {
                script: {
                    shape._index = (shape._index + 1) % root.shapes.length;
                    shape.name = root.shapes[shape._index];
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: shape
                    property: "_kick"
                    to: 130
                    duration: 350
                    easing.type: Easing.OutSine
                }
                SequentialAnimation {
                    NumberAnimation {
                        target: shape
                        property: "scale"
                        to: 1.12
                        duration: 90
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: shape
                        property: "scale"
                        to: 1
                        duration: 140
                        easing.type: Easing.OutQuad
                    }
                }
            }
            ScriptAction {
                script: {
                    shape._target = (shape._target + 130) % 360;
                    shape._kick = 0;
                }
            }
        }
    }
}
