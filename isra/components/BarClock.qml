import QtQuick

import qs.style

Rectangle {
    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
    radius: 18
    implicitWidth: clockTime.implicitWidth + clockDate.implicitWidth + 60
    implicitHeight: 32

    Row {
        anchors.centerIn: parent

        Text {
            id: clockTime
            color: Colors.md3.on_surface
            font.family: Config.fontFamily
            font.pixelSize: 14

            property string timeFormat: (Config.showSeconds ? "hh:mm:ss" : "hh:mm") + ["", " ap", " AP"][Config.hourFormat]
            text: Qt.formatTime(new Date(), timeFormat)

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: parent.text = Qt.formatTime(new Date(), parent.timeFormat)
            }
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

            property string dateFormatStr: ["ddd, dd/MM", "ddd, MM/dd"][Config.dateFormat]
            text: Qt.formatDate(new Date(), dateFormatStr)

            Timer {
                interval: 60000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: parent.text = Qt.formatDate(new Date(), parent.dateFormatStr)
            }
        }
    }
}
