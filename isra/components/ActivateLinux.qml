import QtQuick

Item {
    id: root
    required property var modelData
    anchors.fill: parent

    Column {
        id: watermark
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 48
        anchors.bottomMargin: 32
        spacing: 0

        Text {
            id: line1
            text: "Activate Linux"
            color: "#ffffff"
            opacity: 0.4
            font.family: "Segoe UI Semilight"
            font.pixelSize: 28
            font.weight: Font.Light
            renderType: Text.NativeRendering
            antialiasing: true
        }

        Text {
            id: line2
            text: "Go to Settings to activate Linux."
            color: "#ffffff"
            opacity: 0.4
            font.family: "Segoe UI Semilight"
            font.pixelSize: 15
            font.weight: Font.Normal
            renderType: Text.NativeRendering
            antialiasing: true
        }
    }
}