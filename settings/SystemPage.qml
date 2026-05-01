import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.style
import qs.services
import qs.settings.components

PageBase {
    title: "System"
    subtitle: "About and script paths"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            Layout.bottomMargin: 8
            spacing: 32

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                Image {
                    source: Quickshell.iconPath(SystemInfo.logo) || "image://icon/" + SystemInfo.logo
                    sourceSize.width: 96
                    sourceSize.height: 96
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                Text {
                    text: SystemInfo.distroName
                    font.family: Config.fontFamily
                    font.pixelSize: 64
                    font.weight: Font.Bold
                    color: Colors.md3.on_surface
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                font.family: Config.fontMonospace
                font.pixelSize: 13
                color: Colors.md3.on_surface_variant
                text: "<b><font color='" + Colors.md3.on_surface + "'>kernel</font></b> " + SystemInfo.kernel + " <font color='" + Colors.md3.outline + "'>•</font> " + "<b><font color='" + Colors.md3.on_surface + "'>session</font></b> " + SystemInfo.session + " <font color='" + Colors.md3.outline + "'>•</font> " + "<b><font color='" + Colors.md3.on_surface + "'>uptime</font></b> " + SystemInfo.uptime
                textFormat: Text.RichText
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 88
            radius: 24
            color: Colors.md3.primary

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 16

                Image {
                    source: "/usr/share/icons/hicolor/scalable/apps/org.quickshell.svg"
                    sourceSize.width: 48
                    sourceSize.height: 48
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    Text {
                        text: "Israshell v0.5.1"
                        font.family: Config.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        color: Colors.md3.on_primary
                    }

                    Text {
                        text: "Quickshell Environment"
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Colors.md3.on_primary
                        opacity: 0.8
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: 40
                    implicitWidth: ghLbl.implicitWidth + 32
                    radius: 20
                    color: Colors.md3.on_primary

                    Text {
                        id: ghLbl
                        anchors.centerIn: parent
                        text: "GitHub ↗"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Colors.md3.primary
                    }

                    MouseArea {
                        id: ghMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally("https://github.com/hireri/israshell")
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 4
            rowSpacing: 4

            HardwareCard {
                labelText: "CPU"
                valueText: SystemInfo.cpu
                topLeftRadius: 16
                topRightRadius: 8
                bottomLeftRadius: 8
                bottomRightRadius: 8
            }
            HardwareCard {
                labelText: "GPU"
                valueText: SystemInfo.gpu
                topLeftRadius: 8
                topRightRadius: 16
                bottomLeftRadius: 8
                bottomRightRadius: 8
            }
            HardwareCard {
                labelText: "Memory"
                valueText: SystemInfo.memory
                topLeftRadius: 4
                topRightRadius: 4
                bottomLeftRadius: 16
                bottomRightRadius: 4
            }
            HardwareCard {
                labelText: "Motherboard"
                valueText: SystemInfo.motherboard
                topLeftRadius: 4
                topRightRadius: 4
                bottomLeftRadius: 4
                bottomRightRadius: 16
            }
        }

        SectionCard {
            label: "Script paths"
            Layout.fillWidth: true

            SettingInput {
                label: "Screenshot"
                sublabel: "Capture script"
                value: Config.screencap.screenshotPath
                fieldWidth: 220
                onCommitted: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            screenshotPath: v
                        })
                    })
            }

            SettingInput {
                label: "Screen record"
                sublabel: "Recording script"
                value: Config.screencap.recordPath
                fieldWidth: 220
                onCommitted: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            recordPath: v
                        })
                    })
            }

            SettingInput {
                label: "CTS"
                sublabel: "Circle-to-search"
                value: Config.screencap.ctsPath ?? ""
                fieldWidth: 220
                onCommitted: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            ctsPath: v
                        })
                    })
            }

            SettingInput {
                label: "OCR"
                sublabel: "Text recognition"
                value: Config.screencap.ocrPath ?? ""
                fieldWidth: 220
                onCommitted: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            ocrPath: v
                        })
                    })
            }

            SettingInput {
                label: "Songrec"
                sublabel: "Song recognition"
                value: Config.screencap.songrecPath ?? ""
                fieldWidth: 220
                onCommitted: v => Config.update({
                        screencap: Object.assign({}, Config.screencap, {
                            songrecPath: v
                        })
                    })
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    component HardwareCard: Rectangle {
        Layout.fillWidth: true
        implicitHeight: 72
        radius: 12
        color: Colors.md3.surface_container

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            anchors.leftMargin: 16
            spacing: 4

            Text {
                text: parent.parent.labelText
                font.family: Config.fontFamily
                font.pixelSize: 11
                font.letterSpacing: 1.1
                color: Colors.md3.outline
            }
            Text {
                text: parent.parent.valueText
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.weight: Font.Medium
                color: Colors.md3.on_surface
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        required property string labelText
        required property string valueText
    }
}
