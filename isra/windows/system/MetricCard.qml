import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.style

ClippingRectangle {
    id: root

    property string label: ""
    property string icon: ""
    property string shape: "circle"
    property string value: ""
    property string sublabel: ""
    property string tone: "neutral"
    property var history: []
    property real scaleMax: 100

    property color accent: Colors.md3.primary
    property color accentInk: Colors.md3.on_primary
    readonly property color ink: root.tone === "bad" ? Colors.md3.on_error_container : Colors.md3.on_surface

    implicitHeight: 158
    radius: 24
    color: root.tone === "bad" ? Colors.md3.error_container : Config.dim(Colors.md3.surface_container)

    Behavior on color {
        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    WaveGraph {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: 0
        }
        height: 64
        points: root.history
        scaleMax: root.scaleMax
        color: root.accent
    }

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 16
        }
        spacing: 10

        ShapeIcon {
            size: 32
            shape: root.shape
            icon: root.icon
            fill: root.accent
            ink: root.accentInk
        }

        Text {
            Layout.fillWidth: true
            text: root.label
            font.family: Config.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            color: root.ink
            elide: Text.ElideRight
        }

        Text {
            text: root.value
            font.family: Config.fontFamily
            font.pixelSize: 26
            font.weight: Font.Medium
            font.features: { "tnum": 1 }
            color: root.ink
        }
    }

    Text {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 16
            rightMargin: 16
            topMargin: 58
        }
        text: root.sublabel
        font.family: Config.fontFamily
        font.pixelSize: 11
        color: Qt.alpha(root.ink, 0.75)
        elide: Text.ElideRight
    }
}
