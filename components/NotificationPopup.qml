import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.style
import qs.services

PanelWindow {
    id: popupWindow
    anchors.top: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Overlay
    exclusiveZone: 0
    margins.top: Config.floatingBar ? 64 : 54
    margins.right: 12

    implicitWidth: 320
    implicitHeight: contentCol.implicitHeight
    color: "transparent"

    visible: !NotificationService.dnd

    Column {
        id: contentCol
        spacing: 8
        width: 320

        Repeater {
            model: NotificationService.activeNotifications
            delegate: Rectangle {
                implicitWidth: 320
                implicitHeight: 74
                color: Colors.md3.surface_container_high
                radius: 16
                border.color: Colors.md3.outline_variant
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 10
                        color: Colors.md3.surface_container
                        clip: true
                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            fillMode: Image.PreserveAspectFit
                            source: {
                                let icon = modelData.image || modelData.appIcon || "dialog-information";
                                if (icon.startsWith("/"))
                                    return "file://" + icon;
                                return "image://icon/" + icon;
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: modelData.summary
                            color: Colors.md3.on_surface
                            font.family: Config.fontFamily
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            text: modelData.body
                            color: Colors.md3.on_surface_variant
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            maximumLineCount: 2
                        }
                    }
                }

                Timer {
                    interval: modelData.expireTimeout > 0 ? modelData.expireTimeout : 5000
                    running: true
                    onTriggered: modelData.dismiss()
                }
            }
        }
    }
}
