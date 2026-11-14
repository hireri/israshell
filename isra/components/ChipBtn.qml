import QtQuick
import qs.style

Item {
    id: cb
    property var card: null
    property string glyph: ""
    property bool active: false
    signal clicked
    height: 36
    width: 36
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: cb.active ? cb.card.colPrimary : cb.card.colSurfaceContainerHigh
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }
    Text {
        anchors.centerIn: parent
        text: cb.glyph
        font.family: Config.fontFamily
        font.pixelSize: 15
        color: cb.active ? cb.card.colOnPrimary : cb.card.colOnPrimaryContainer
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: cb.clicked()
    }
}
