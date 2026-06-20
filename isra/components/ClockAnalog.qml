import QtQuick
import QtQuick.Effects
import qs.style

Item {
    id: root

    property var currentTime
    property string clockFont
    property color textColor
    property color subColor
    property int halign
    property bool showSeconds
    property bool is12h
    property int analogSize

    property int    fontWeight:    Config.clock.hourWeight    ?? 600
    property real   fontWidth:     Config.clock.fontWidth     ?? 100
    property real   fontRoundness: Config.clock.fontRoundness ?? 0

    readonly property bool isGoogleSansFlex: root.clockFont === "Google Sans Flex"
    readonly property var  mainAxes:         ({ "wght": root.fontWeight, "wdth": root.fontWidth, "ROND": root.fontRoundness })

    implicitWidth:  analogSize
    implicitHeight: analogSize + (Config.clock.showDate ? Config.clock.dateSpacing + dateLbl.implicitHeight : 0)

    Item {
        id: face
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.analogSize
        height: root.analogSize

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Colors.md3.surface_container_high ?? Colors.md3.surface_container ?? Qt.rgba(0.95, 0.95, 0.95, 1)

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: ((Config.clock.shadowBlur ?? 16) / 32)
                shadowColor: Qt.alpha("black", Config.clock.shadowOpacity ?? 0.2)
                shadowScale: 1.04
            }
        }

        Repeater {
            model: 12
            Item {
                anchors.fill: parent
                rotation: index * 30
                Rectangle {
                    width: 6
                    height: index % 3 === 0 ? 10 : 6
                    radius: width / 2
                    color: index % 3 === 0
                           ? Qt.alpha(root.subColor, 0.6)
                           : Qt.alpha(root.subColor, 0.3)
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        Column {
            id: innerDigitalClock
            visible: Config.clock.showDigitalInside ?? false
            anchors.centerIn: parent
            spacing: -root.analogSize * 0.1
            z: 1
            opacity: 0.5

            Text {
                id: innerHours
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.subColor
                text: Qt.formatTime(root.currentTime, root.is12h ? "hh" : "hh")

                font.family:        root.clockFont
                font.pixelSize:     root.analogSize * 0.28
                font.weight:        root.isGoogleSansFlex ? Font.Normal : root.fontWeight
                font.letterSpacing: -0.5
                font.features:      { "tnum": 1 }
                font.variableAxes:  root.isGoogleSansFlex ? root.mainAxes : ({})
            }

            Text {
                id: innerMinutes
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.subColor
                text: Qt.formatTime(root.currentTime, "mm")

                font.family:        root.clockFont
                font.pixelSize:     root.analogSize * 0.28
                font.weight:        root.isGoogleSansFlex ? Font.Normal : root.fontWeight
                font.letterSpacing: -0.5
                font.features:      { "tnum": 1 }
                font.variableAxes:  root.isGoogleSansFlex ? root.mainAxes : ({})
            }
        }

        Item {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            rotation: root.currentTime.getMinutes() * 6
                      + root.currentTime.getSeconds() * 0.1
                      + root.currentTime.getMilliseconds() * (0.1 / 1000)
            z: 3

            Rectangle {
                width: root.analogSize * 0.05
                height: root.analogSize * 0.38 + width
                radius: width / 2
                color: root.subColor
                anchors.bottom: parent.verticalCenter
                anchors.bottomMargin: -radius
                anchors.horizontalCenter: parent.horizontalCenter
                antialiasing: true
            }
        }

        Item {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            rotation: (root.currentTime.getHours() % 12) * 30
                      + root.currentTime.getMinutes() * 0.5
                      + root.currentTime.getSeconds() * (0.5 / 60)
            z: 4

            Rectangle {
                width: root.analogSize * 0.08
                height: root.analogSize * 0.25 + width
                radius: width / 2
                color: root.textColor
                anchors.bottom: parent.verticalCenter
                anchors.bottomMargin: -radius
                anchors.horizontalCenter: parent.horizontalCenter
                antialiasing: true
            }
        }

        Item {
            visible: root.showSeconds
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            rotation: root.currentTime.getSeconds() * 6
                      + root.currentTime.getMilliseconds() * 0.006
            z: 5

            Rectangle {
                width: root.analogSize * 0.08
                height: width
                radius: width / 2
                color: Colors.md3.tertiary ?? Colors.md3.error ?? "#ff6b6b"
                y: root.analogSize * 0.15
                anchors.horizontalCenter: parent.horizontalCenter
                antialiasing: true
            }
        }

        Rectangle {
            width: root.analogSize * 0.05
            height: width
            radius: width / 2
            color: root.textColor
            anchors.centerIn: parent
            z: 10
            antialiasing: true
        }
    }

    Text {
        id: dateLbl
        visible: Config.clock.showDate
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: face.bottom
            topMargin: Config.clock.dateSpacing
        }
        font {
            family:   root.clockFont
            pixelSize: Config.clock.dateSize
            weight:   Font.Normal
        }
        color: root.subColor
        opacity: 0.8
        text: Qt.formatDate(root.currentTime, ["ddd, dd/MM", "ddd, MM/dd"][Config.dateFormat] ?? "ddd, dd/MM")
    }
}
