import QtQuick
import Quickshell.Widgets
import qs.style
import qs.icons
import qs.components

Item {
    id: root

    property string icon: ""
    property string source: ""
    property string glyph: ""
    property string tip: ""
    property color tint: Colors.md3.on_surface_variant
    property int size: 36
    property int iconSize: 20
    signal clicked

    implicitWidth: size
    implicitHeight: size
    opacity: enabled ? 1.0 : 0.38

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.tint
        opacity: ma.pressed ? 0.16 : ma.containsMouse ? 0.08 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
    }

    Item {
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        scale: ma.pressed ? 0.85 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: root.icon !== ""
            name: root.icon
            iconSize: root.iconSize
            color: root.tint
            transitionType: "none"
        }
        IconImage {
            anchors.fill: parent
            visible: root.source !== ""
            source: root.source
        }
        Text {
            anchors.centerIn: parent
            visible: root.glyph !== ""
            text: root.glyph
            font.pixelSize: root.iconSize - 2
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Tooltip {
        text: root.tip
        suppressed: root.tip === "" || !root.visible
    }
}
