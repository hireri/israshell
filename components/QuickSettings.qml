import QtQuick

import qs.style

Rectangle {
    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
    radius: 12
    width: label.implicitWidth + 20
    height: 32

    Text {
        id: label
        anchors.centerIn: parent
        text: "quick settings"
        color: Colors.md3.on_surface
        font.family: Config.fontFamily
        font.pixelSize: 14
    }
}
