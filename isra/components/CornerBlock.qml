import QtQuick

Item {
    id: block

    property int type: 0
    property int cornerRadius: 26
    property string cornerColor: "black"

    property real maskProgress: 0
    property color outlineColor: "transparent"

    width: cornerRadius
    height: cornerRadius
    clip: true

    Rectangle {
        width: block.cornerRadius * 4
        height: block.cornerRadius * 4
        radius: block.cornerRadius * 2
        color: "transparent"

        border.width: block.cornerRadius * (1 + block.maskProgress)
        border.color: block.cornerColor

        x: (block.type === 1 || block.type === 3) ? -block.cornerRadius * 2 : -block.cornerRadius
        y: (block.type === 2 || block.type === 3) ? -block.cornerRadius * 2 : -block.cornerRadius
    }

    Rectangle {
        readonly property real d: block.cornerRadius * 2 * (1 - block.maskProgress)
        width: d
        height: d
        radius: d / 2
        color: "transparent"
        border.width: 1
        border.color: block.outlineColor
        x: ((block.type === 1 || block.type === 3) ? 0 : block.cornerRadius) - d / 2
        y: ((block.type === 2 || block.type === 3) ? 0 : block.cornerRadius) - d / 2
    }
}
