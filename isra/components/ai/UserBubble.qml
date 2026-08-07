pragma ComponentBehavior: Bound

import QtQuick
import qs.style

Rectangle {
    id: root

    required property var entry
    property bool isError: false
    property real maxWidth: 600

    readonly property var attachments: entry.attachments ?? []

    radius: 16
    color: Qt.alpha(isError ? Colors.md3.error_container : Colors.md3.surface_container_high, Config.blurOpacity)
    border.width: 1
    border.color: Colors.md3.outline_variant

    implicitWidth: Math.max(bubbleText.visible ? bubbleText.width : 0, attachRow.visible ? attachRow.width : 0) + 24
    implicitHeight: bubbleText.visible ? (bubbleText.y + bubbleText.height + 8) : (attachRow.visible ? attachRow.y + attachRow.height + 8 : 16)

    Row {
        id: attachRow
        visible: root.attachments.length > 0
        x: 12
        y: 8
        spacing: 6

        Repeater {
            model: root.attachments

            AttachmentThumb {
                required property var modelData
                attachment: modelData
            }
        }
    }

    Text {
        id: bubbleText
        x: 12
        y: attachRow.visible ? attachRow.y + attachRow.height + 8 : 8
        visible: text !== ""
        width: Math.min(implicitWidth, root.maxWidth)
        wrapMode: Text.Wrap
        text: root.entry.text
        color: root.isError ? Colors.md3.on_error_container : Colors.md3.on_surface
        font.pixelSize: 15
        font.family: Config.fontFamily
        lineHeight: 1.2
    }
}
