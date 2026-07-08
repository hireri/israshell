import QtQuick
import qs.style
import qs.icons

Rectangle {
    id: root

    property string label: ""
    signal removed

    implicitHeight: 32
    implicitWidth: exiting ? 0 : Math.max(24, content.implicitWidth + 24 - (mouseArea.pressed && mouseArea.containsMouse ? 20 : 0))
    opacity: exiting ? 0 : 1
    clip: true

    property bool exiting: false

    radius: 16
    color: Colors.md3.surface_container_high

    Behavior on implicitWidth {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.exiting = true;
            exitTimer.start();
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label + "  󰅖"
            font.family: Config.fontFamily
            font.pixelSize: 12
            color: Colors.md3.on_surface_variant
        }
    }

    Timer {
        id: exitTimer
        interval: 120
        onTriggered: root.removed()
    }
}