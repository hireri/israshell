import QtQuick
import qs.style
import qs.services
import qs.icons
import Quickshell.Widgets

Item {
    id: root

    property string overlayName: ""

    readonly property real u: {
        if (root.width <= 0 || root.height <= 0)
            return 1;
        return Math.max(0.7, Math.min(1.5, Math.min(root.width / 700, root.height / 260)));
    }

    readonly property real pad: 22 * root.u

    readonly property real salt: Math.floor(Date.now() / 86400000)
    readonly property string scenePath: WeatherAssets.scenePath(WeatherReadout.code, WeatherReadout.isDay, root.salt)

    ClippingRectangle {
        anchors.fill: parent
        radius: 32 * root.u
        color: Colors.md3.surface_container_high

        Item {
            id: band
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * 0.5
            clip: true

            Image {
                id: sceneImage
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Math.max(band.height, width * (198 / 1200))
                source: root.scenePath === "" ? "" : "file://" + root.scenePath
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: Math.ceil(width)
                asynchronous: true
                cache: true
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
            }

            WeatherOverlay {
                anchors.fill: parent
                code: WeatherReadout.code
                isDay: WeatherReadout.isDay
                overlayName: root.overlayName
                visible: sceneImage.status === Image.Ready
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 46 * root.u
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Colors.md3.surface_container_high }
                    GradientStop { position: 1.0; color: Qt.rgba(Colors.md3.surface_container_high.r, Colors.md3.surface_container_high.g, Colors.md3.surface_container_high.b, 0) }
                }
            }
        }

        Item {
            id: textArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: band.top
            anchors.bottomMargin: -6 * root.u
            anchors.leftMargin: root.pad
            anchors.rightMargin: root.pad
            anchors.topMargin: root.pad

            readonly property real line1H: Math.max(tempText.implicitHeight, descText.implicitHeight)
            readonly property real line2H: Math.max(locationText.implicitHeight, arrowsRow.implicitHeight)
            readonly property real lineSpacing: -12 * root.u
            readonly property real blockH: line1H + lineSpacing + line2H
            readonly property real blockTop: (height - blockH) / 2

            WeatherIcon {
                id: weatherIcon
                anchors.left: parent.left
                y: textArea.blockTop + textArea.blockH / 2 - height / 2
                code: WeatherReadout.code
                isDay: WeatherReadout.isDay
                iconSize: 92 * root.u
            }

            Text {
                id: tempText
                anchors.left: weatherIcon.right
                anchors.leftMargin: 14 * root.u
                y: textArea.blockTop
                text: WeatherReadout.temp
                font.family: Config.fontFamily
                font.pixelSize: 66 * root.u
                font.weight: Font.DemiBold
                color: Colors.md3.primary
            }

            Text {
                id: locationText
                anchors.left: weatherIcon.right
                anchors.leftMargin: 14 * root.u
                y: textArea.blockTop + textArea.line1H + textArea.lineSpacing
                text: WeatherReadout.location
                font.family: Config.fontFamily
                font.pixelSize: 25 * root.u
                font.weight: Font.Medium
                color: Colors.md3.on_surface_variant
            }

            Text {
                id: descText
                anchors.right: parent.right
                y: textArea.blockTop
                text: WeatherReadout.desc
                font.family: Config.fontFamily
                font.pixelSize: 41 * root.u
                font.weight: Font.Medium
                color: Colors.md3.primary
            }

            Row {
                id: arrowsRow
                anchors.right: parent.right
                y: textArea.blockTop + textArea.line1H + textArea.lineSpacing
                spacing: 5 * root.u

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "arrow-upward"
                    iconSize: 22 * root.u
                    color: Colors.md3.on_surface_variant
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: WeatherReadout.high
                    font.family: Config.fontFamily
                    font.pixelSize: 25 * root.u
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface_variant
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "/"
                    font.family: Config.fontFamily
                    font.pixelSize: 25 * root.u
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface_variant
                }

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "arrow-downward"
                    iconSize: 22 * root.u
                    color: Colors.md3.on_surface_variant
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: WeatherReadout.low
                    font.family: Config.fontFamily
                    font.pixelSize: 25 * root.u
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface_variant
                }
            }
        }
    }
}
