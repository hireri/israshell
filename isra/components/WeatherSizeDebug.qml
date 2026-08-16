import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.style

PanelWindow {
    id: debugWindow

    anchors.top: true
    anchors.left: true
    margins.top: 40
    margins.left: 40

    implicitWidth: row.implicitWidth + 40
    implicitHeight: row.implicitHeight + 40
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 30

        Repeater {
            model: [
                { w: 320, h: 320, label: "square" },
                { w: 620, h: 320, label: "wide" },
                { w: 620, h: 560, label: "tall" }
            ]

            Column {
                required property var modelData
                spacing: 6

                Text {
                    text: modelData.label + " " + modelData.w + "x" + modelData.h
                    color: "white"
                    font.pixelSize: 14
                }

                WeatherCardVisual {
                    width: modelData.w
                    height: modelData.h
                    screen: debugWindow.screen
                }
            }
        }
    }
}
