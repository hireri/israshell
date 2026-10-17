import QtQuick
import QtQuick.Shapes
import qs.style

Item {
    id: root

    property real value: 0
    property color color: Colors.md3.primary
    property color trackColor: Colors.md3.secondary_container
    property real amplitude: 2.5
    property real wavelength: 18
    property real phase: 0
    property bool animated: true

    property real shown: value
    Behavior on shown {
        NumberAnimation {
            duration: 450
            easing.type: Easing.OutCubic
        }
    }

    implicitWidth: 120
    implicitHeight: 12

    readonly property real split: 2 + (width - 4) * Math.max(0, Math.min(1, shown))
    readonly property var wave: {
        const pts = [];
        const c = height / 2;
        const y = x => c + amplitude * Math.sin((x + phase) / wavelength * 2 * Math.PI);
        for (let x = 2; x < split; x += 2)
            pts.push(Qt.point(x, y(x)));
        pts.push(Qt.point(split, y(split)));
        return pts.length > 1 ? pts : [Qt.point(2, c), Qt.point(2.1, c)];
    }

    NumberAnimation on phase {
        from: 0
        to: -root.wavelength
        duration: 900
        loops: Animation.Infinite
        running: root.visible && root.animated
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.split + 8 < root.width - 2 ? root.trackColor : "transparent"
            strokeWidth: 4
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            startX: Math.min(root.width - 2, root.split + 8)
            startY: root.height / 2
            PathLine {
                x: root.width - 2
                y: root.height / 2
            }
        }

        ShapePath {
            strokeColor: root.color
            strokeWidth: 4
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            fillColor: "transparent"
            PathPolyline {
                path: root.wave
            }
        }
    }
}
