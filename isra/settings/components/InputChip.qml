import QtQuick
import qs.style
import qs.icons

Rectangle {
    id: root

    property string label: ""
    signal removed

    implicitHeight: 32
    implicitWidth: exiting ? 0 : (content.implicitWidth + (mouseArea.pressed ? 18 : 24))
    opacity: exiting ? 0 : 1
    clip: true

    property bool exiting: false

    radius: 16
    color: Colors.md3.surface_container_high

    Behavior on implicitWidth {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
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
        interval: 180
        onTriggered: root.removed()
    }
}
