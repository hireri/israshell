pragma ComponentBehavior: Bound

import QtQuick
import qs.style

Item {
    id: root

    property string body: ""
    property real maxWidth: 600
    property real fontSize: 15

    readonly property real barWidth: 3
    readonly property real gap: 12

    implicitWidth: Math.min(quoteText.implicitWidth, root.maxWidth - root.barWidth - root.gap) + root.barWidth + root.gap
    implicitHeight: quoteText.implicitHeight

    Rectangle {
        width: root.barWidth
        height: parent.height
        radius: root.barWidth / 2
        color: Colors.md3.outline
    }

    Text {
        id: quoteText
        anchors.left: parent.left
        anchors.leftMargin: root.barWidth + root.gap
        width: Math.min(implicitWidth, root.maxWidth - root.barWidth - root.gap)
        text: root.body
        textFormat: Text.MarkdownText
        wrapMode: Text.Wrap
        color: Colors.md3.on_surface_variant
        linkColor: Colors.md3.primary
        font.pixelSize: root.fontSize
        font.family: Config.fontFamily
        onLinkActivated: link => Qt.openUrlExternally(link)
    }
}
