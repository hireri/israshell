pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import qs.style

Item {
    id: root

    property string text: ""
    property bool isError: false
    property real maxWidth: 600

    implicitWidth: isError ? errorText.width : markdown.width
    implicitHeight: isError ? errorText.height : markdown.height

    layer.enabled: true
    layer.effect: DropShadow {
        radius: 6
        samples: 13
        horizontalOffset: 0
        verticalOffset: 2
        color: Qt.alpha(Colors.md3.background, 0.95)
    }

    MarkdownView {
        id: markdown
        visible: !root.isError
        text: root.text
        maxWidth: root.maxWidth
        textColor: Colors.md3.on_surface
        fontSize: 15
    }

    Text {
        id: errorText
        visible: root.isError
        width: Math.min(implicitWidth, root.maxWidth)
        text: root.text
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        color: Colors.md3.error
        font.pixelSize: 15
        font.family: Config.fontFamily
        lineHeight: 1.2
    }
}
