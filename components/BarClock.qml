import QtQuick

import qs.style

Rectangle {
    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
    radius: Config.floatingBar ? 18 : 12
    implicitWidth: clockTime.implicitWidth + clockDate.implicitWidth + 60
    implicitHeight: 32

    Row {
        anchors.centerIn: parent

        Text {
            id: clockTime
            color: Colors.md3.on_surface
            font.family: Config.fontFamily
            font.pixelSize: 14

            function update() {
                const ap = ["", " ap", " AP"][Config.hourFormat];
                text = Qt.formatTime(new Date(), (Config.showSeconds ? "hh:mm:ss" : "hh:mm") + ap);
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: parent.update()
            }

            Component.onCompleted: update()
        }

        Text {
            text: "  •  "
            color: Colors.md3.on_surface
            font.family: Config.fontFamily
            font.pixelSize: 14
        }

        Text {
            id: clockDate
            color: Colors.md3.on_surface
            font.family: Config.fontFamily
            font.pixelSize: 14

            function currentDate() {
                text = Qt.formatDate(new Date(), "ddd, dd/MM");
            }

            Timer {
                interval: 24000
                running: true
                repeat: true
                onTriggered: parent.currentDate()
            }

            Component.onCompleted: currentDate()
        }
    }
}
