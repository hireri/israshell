import QtQuick
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    required property var screen

    readonly property int gap: 3
    readonly property int pad: gap + 2
    readonly property color accent: ScreencapService.recordingGif ? Colors.md3.tertiary : Colors.md3.error
    readonly property color onAccent: ScreencapService.recordingGif ? Colors.md3.on_tertiary : Colors.md3.on_error

    readonly property bool hasRegion: ScreencapService.isRecording && ScreencapService.recordRegion !== null
    readonly property real rx: hasRegion ? ScreencapService.recordRegion.x - screen.x : 0
    readonly property real ry: hasRegion ? ScreencapService.recordRegion.y - screen.y : 0
    readonly property real rw: hasRegion ? ScreencapService.recordRegion.w : 0
    readonly property real rh: hasRegion ? ScreencapService.recordRegion.h : 0

    readonly property bool intersects: hasRegion && rx < root.width && ry < root.height && rx + rw > 0 && ry + rh > 0
    readonly property bool coversScreen: hasRegion && rx <= 0 && ry <= 0 && rx + rw >= root.width && ry + rh >= root.height
    readonly property bool active: intersects && !coversScreen

    readonly property bool ownsCentre: hasRegion && (rx + rw / 2) >= 0 && (rx + rw / 2) < root.width && (ry + rh / 2) >= 0 && (ry + rh / 2) < root.height

    readonly property real outlineTop: ry - pad
    readonly property real outlineBottom: ry + rh + pad

    readonly property bool chipBelow: outlineBottom + 8 + chip.height <= root.height - 8
    readonly property bool chipAbove: !chipBelow && outlineTop - 8 - chip.height >= 8
    readonly property bool chipShown: visible && active && ownsCentre && (chipBelow || chipAbove)
    readonly property Item chipItem: chip

    Rectangle {
        id: outline
        visible: root.active
        x: root.rx - root.pad
        y: root.ry - root.pad
        width: root.rw + 2 * root.pad
        height: root.rh + 2 * root.pad
        color: "transparent"
        radius: 6
        border.width: 2
        border.color: root.accent
    }

    Rectangle {
        id: chip
        visible: root.chipShown
        height: 32
        width: stopBtn.x + stopBtn.width + 4
        radius: 16
        color: Colors.md3.surface_container
        border.width: 1
        border.color: Colors.md3.outline_variant
        x: Math.max(8, Math.min(root.width - width - 8, root.rx + root.rw / 2 - width / 2))
        y: root.chipBelow ? root.outlineBottom + 8 : root.outlineTop - 8 - height

        Rectangle {
            id: dot
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: 5
            color: root.accent
        }

        Text {
            id: timeText
            x: dot.x + dot.width + 8
            anchors.verticalCenter: parent.verticalCenter
            text: ScreencapService.recordingTime
            font.family: Config.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            color: Colors.md3.on_surface
            font.features: ({ "tnum": 1 })
        }

        Rectangle {
            id: stopBtn
            x: timeText.x + timeText.width + 8
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 24
            radius: 12
            color: root.accent

            MaterialIcon {
                anchors.centerIn: parent
                name: "stop"
                filled: true
                iconSize: 16
                color: root.onAccent
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ScreencapService.stopRecording()
            }
        }
    }
}
