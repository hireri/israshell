import QtQuick

// 0 = top-left, 1 = top-right, 2 = bottom-left, 3 = bottom-right
Item {
    id: block

    property int type: 0
    property int cornerRadius: 26
    property string cornerColor: "black"

    width: cornerRadius
    height: cornerRadius
    clip: true

    Rectangle {
        width: block.cornerRadius * 4
        height: block.cornerRadius * 4
        radius: block.cornerRadius * 2
        color: "transparent"

        border.width: block.cornerRadius
        border.color: block.cornerColor

        x: (block.type === 1 || block.type === 3) ? -block.cornerRadius * 2 : -block.cornerRadius
        y: (block.type === 2 || block.type === 3) ? -block.cornerRadius * 2 : -block.cornerRadius
    }
}
