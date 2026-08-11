import QtQuick
import qs.style

Rectangle {
    id: pb

    property string label: ""
    property bool primary: false
    property bool showBtn: true
    signal tapped

    implicitWidth: showBtn ? lbl.implicitWidth + 22 : 0
    implicitHeight: showBtn ? 30 : 0
    radius: height / 2
    color: ma.containsMouse ? (primary ? Colors.md3.primary : Colors.md3.secondary_container) : (primary ? Colors.md3.primary_container : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity))
    Behavior on color {
        ColorAnimation {
            duration: 90
        }
    }

    Text {
        id: lbl
        anchors.centerIn: parent
        text: pb.label
        color: ma.containsMouse ? (pb.primary ? Colors.md3.on_primary : Colors.md3.on_secondary_container) : (pb.primary ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant)
        font.pixelSize: 12
        font.family: Config.fontFamily
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pb.tapped()
    }
}
