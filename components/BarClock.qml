import QtQuick

import qs.style

Rectangle {
    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
    radius: 12
    width: clockText.implicitWidth + 40
    height: 32

    Text {
        id: clockText
        anchors.centerIn: parent
        color: Colors.md3.on_surface
        font.family: Config.fontFamily
        font.pixelSize: 14

        function update() {
            text = Qt.formatTime(new Date(), "hh:mm") + " " + Qt.formatDate(new Date(), "ddd dd/MM");
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: parent.update()
        }

        Component.onCompleted: update()
    }
}
