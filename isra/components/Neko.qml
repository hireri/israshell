pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.services
import qs.style

Item {
    id: root
    required property var modelData

    readonly property real screenOffsetX: modelData ? modelData.x : 0
    readonly property real screenOffsetY: modelData ? modelData.y : 0

    readonly property real spriteSize: Config.neko.size

    x: (NekoService.x - screenOffsetX) - spriteSize / 2
    y: (NekoService.y - screenOffsetY) - spriteSize / 2
    width: spriteSize
    height: spriteSize

    Image {
        anchors.fill: parent
        source: "file://" + Quickshell.shellDir + "/sprites/oneko.gif"
        smooth: false
        mipmap: false
        fillMode: Image.Stretch
        sourceClipRect: Qt.rect(NekoService.spriteCol * 32, NekoService.spriteRow * 32, 32, 32)
    }
}
