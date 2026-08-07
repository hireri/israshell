pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.style
import qs.icons
import "fileicons.js" as FileIcons

Item {
    id: root

    required property var attachment

    readonly property bool isImage: attachment.kind === "image"

    width: isImage ? 90 : Math.min(fileChipText.implicitWidth + 34, 140)
    height: isImage ? 90 : 26

    ClippingRectangle {
        visible: root.isImage
        anchors.fill: parent
        radius: 10
        clip: true
        color: Colors.md3.surface_container_highest

        Image {
            anchors.fill: parent
            source: root.isImage ? ("data:" + root.attachment.mimeType + ";base64," + root.attachment.base64) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    Rectangle {
        visible: !root.isImage
        anchors.fill: parent
        radius: height / 2
        color: Colors.md3.surface_container_highest
        border.width: 1
        border.color: Colors.md3.outline_variant

        Row {
            anchors.centerIn: parent
            spacing: 4

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: FileIcons.forName(root.attachment.name)
                iconSize: 12
                color: Colors.md3.on_surface_variant
            }

            Text {
                id: fileChipText
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 96)
                elide: Text.ElideMiddle
                text: root.attachment.name
                color: Colors.md3.on_surface_variant
                font.pixelSize: 11
                font.family: Config.fontFamily
            }
        }
    }
}
